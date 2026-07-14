// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IPriceOracle {
    function getPrice(address token) external view returns (uint256);
}

contract LendingPool {
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event Liquidate(address indexed liquidator, address indexed borrower, uint256 repayAmount, uint256 seizedCollateral);
    event InterestParamsUpdated(uint256 apr);
    event CollateralParamsUpdated(uint256 ltv, uint256 liquidationThreshold);

    IERC20 public immutable reserveToken;
    IERC20 public immutable collateralToken;
    IPriceOracle public priceOracle;

    uint256 public aprWad;
    uint256 public ltvWad;
    uint256 public liquidationThresholdWad;

    mapping(address => uint256) public deposits;
    uint256 public totalDeposits;

    struct BorrowPosition {
        uint256 principal;
        uint256 interestIndex;
    }
    mapping(address => BorrowPosition) public borrows;
    mapping(address => uint256) public collaterals;

    uint256 private _entered;

    uint256 private constant WAD = 1e18;
    uint256 private constant SECONDS_PER_YEAR = 365 days;

    modifier nonReentrant() {
        require(_entered == 0, "Reentrant");
        _entered = 1;
        _;
        _entered = 0;
    }

    modifier onlyValidApr(uint256 _aprWad) {
        require(_aprWad <= 5 * WAD, "APR too high");
        _;
    }

    constructor(
        address _reserveToken,
        address _collateralToken,
        address _priceOracle,
        uint256 _aprWad,
        uint256 _ltvWad,
        uint256 _liquidationThresholdWad
    ) onlyValidApr(_aprWad) {
        reserveToken = IERC20(_reserveToken);
        collateralToken = IERC20(_collateralToken);
        priceOracle = IPriceOracle(_priceOracle);
        aprWad = _aprWad;
        ltvWad = _ltvWad;
        liquidationThresholdWad = _liquidationThresholdWad;
    }

    function setAPR(uint256 _aprWad) external onlyValidApr(_aprWad) {
        aprWad = _aprWad;
        emit InterestParamsUpdated(_aprWad);
    }

    function setCollateralParams(uint256 _ltvWad, uint256 _liquidationThresholdWad) external {
        require(_ltvWad <= WAD, "bad ltv");
        require(_liquidationThresholdWad <= WAD, "bad threshold");
        ltvWad = _ltvWad;
        liquidationThresholdWad = _liquidationThresholdWad;
        emit CollateralParamsUpdated(_ltvWad, _liquidationThresholdWad);
    }

    function setPriceOracle(address _oracle) external {
        priceOracle = IPriceOracle(_oracle);
    }

    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "zero");
        require(reserveToken.transferFrom(msg.sender, address(this), amount), "transferFrom failed");
        deposits[msg.sender] += amount;
        totalDeposits += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "zero");
        require(deposits[msg.sender] >= amount, "insufficient deposit");
        require(reserveToken.balanceOf(address(this)) >= amount, "insufficient pool liquidity");
        deposits[msg.sender] -= amount;
        totalDeposits -= amount;
        require(reserveToken.transfer(msg.sender, amount), "transfer failed");
        emit Withdraw(msg.sender, amount);
    }

    function depositCollateral(uint256 amount) external nonReentrant {
        require(amount > 0, "zero");
        require(collateralToken.transferFrom(msg.sender, address(this), amount), "transferFrom failed");
        collaterals[msg.sender] += amount;
    }

    function withdrawCollateral(uint256 amount) external nonReentrant {
        require(amount > 0, "zero");
        require(collaterals[msg.sender] >= amount, "not enough collateral");
        collaterals[msg.sender] -= amount;
        if (borrows[msg.sender].principal > 0) {
            require(_healthFactor(msg.sender) >= WAD, "would be unsafe");
        }
        require(collateralToken.transfer(msg.sender, amount), "transfer failed");
    }

    function borrow(uint256 amount) external nonReentrant {
        require(amount > 0, "zero");
        _accrueInterest(msg.sender);
        uint256 collateralValue = _collateralValue(msg.sender);
        uint256 maxBorrowable = (collateralValue * ltvWad) / WAD;
        uint256 currentDebt = borrows[msg.sender].principal;
        require(currentDebt + amount <= maxBorrowable, "exceeds LTV");
        borrows[msg.sender].principal = currentDebt + amount;
        borrows[msg.sender].interestIndex = block.timestamp;
        require(reserveToken.transfer(msg.sender, amount), "transfer failed");
        emit Borrow(msg.sender, amount);
    }

    function repay(uint256 amount) external nonReentrant {
        require(amount > 0, "zero");
        _accrueInterest(msg.sender);
        uint256 debt = borrows[msg.sender].principal;
        require(debt > 0, "no debt");
        uint256 pay = amount > debt ? debt : amount;
        require(reserveToken.transferFrom(msg.sender, address(this), pay), "transferFrom failed");
        borrows[msg.sender].principal = debt - pay;
        borrows[msg.sender].interestIndex = block.timestamp;
        emit Repay(msg.sender, pay);
    }

    function liquidate(address borrower, uint256 repayAmount) external nonReentrant {
        require(repayAmount > 0, "zero");
        _accrueInterest(borrower);
        uint256 debt = borrows[borrower].principal;
        require(debt > 0, "no debt");
        require(_healthFactor(borrower) < liquidationThresholdWad, "not liquidatable");
        uint256 actualRepay = repayAmount > debt ? debt : repayAmount;
        require(reserveToken.transferFrom(msg.sender, address(this), actualRepay), "transferFrom failed");
        borrows[borrower].principal = debt - actualRepay;
        borrows[borrower].interestIndex = block.timestamp;
        uint256 bonusWad = (5 * WAD) / 100;
        uint256 reservePrice = priceOracle.getPrice(address(reserveToken));
        uint256 collateralPrice = priceOracle.getPrice(address(collateralToken));
        uint256 numerator = actualRepay * (WAD + bonusWad) * reservePrice;
        uint256 seizedCollateral = numerator / collateralPrice / WAD;
        if (seizedCollateral > collaterals[borrower]) {
            seizedCollateral = collaterals[borrower];
        }
        collaterals[borrower] -= seizedCollateral;
        require(collateralToken.transfer(msg.sender, seizedCollateral), "transfer failed");
        emit Liquidate(msg.sender, borrower, actualRepay, seizedCollateral);
    }

    function _accrueInterest(address borrower) internal {
        BorrowPosition storage pos = borrows[borrower];
        if (pos.principal == 0) {
            pos.interestIndex = block.timestamp;
            return;
        }
        uint256 last = pos.interestIndex;
        if (last == 0) {
            pos.interestIndex = block.timestamp;
            return;
        }
        uint256 delta = block.timestamp - last;
        if (delta == 0) return;
        uint256 interest = (pos.principal * aprWad * delta) / (SECONDS_PER_YEAR * WAD);
        pos.principal += interest;
        pos.interestIndex = block.timestamp;
    }

    function _healthFactor(address user) internal view returns (uint256) {
        uint256 debt = borrows[user].principal;
        if (debt == 0) return type(uint256).max;
        uint256 collateralValue = _collateralValue(user);
        uint256 adjusted = (collateralValue * liquidationThresholdWad) / WAD;
        return (adjusted * WAD) / debt;
    }

    function _collateralValue(address user) internal view returns (uint256) {
        uint256 collAmount = collaterals[user];
        if (collAmount == 0) return 0;
        uint256 collPrice = priceOracle.getPrice(address(collateralToken));
        uint256 reservePrice = priceOracle.getPrice(address(reserveToken));
        uint256 value = (collAmount * collPrice) / reservePrice;
        return value;
    }

    function currentDebt(address user) external view returns (uint256) {
        BorrowPosition storage pos = borrows[user];
        if (pos.principal == 0) return 0;
        uint256 delta = block.timestamp - pos.interestIndex;
        if (delta == 0) return pos.principal;
        uint256 interest = (pos.principal * aprWad * delta) / (SECONDS_PER_YEAR * WAD);
        return pos.principal + interest;
    }

    function healthFactor(address user) external view returns (uint256) {
        uint256 debt = borrows[user].principal;
        if (debt == 0) return type(uint256).max;
        uint256 delta = block.timestamp - borrows[user].interestIndex;
        uint256 simulatedDebt = debt + (debt * aprWad * delta) / (SECONDS_PER_YEAR * WAD);
        uint256 collateralValue = _collateralValue(user);
        uint256 adjusted = (collateralValue * liquidationThresholdWad) / WAD;
        return (adjusted * WAD) / simulatedDebt;
    }
}
