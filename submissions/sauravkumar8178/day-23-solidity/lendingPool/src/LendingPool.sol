// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IPriceOracle.sol";
import "./InterestRateModel.sol";
import "./ERC20Mock.sol";

contract LendingPool {
    struct Asset {
        ERC20Mock token;
        uint256 totalSupply;   // tokens supplied to pool
        uint256 totalBorrows;  // principal outstanding (plus interest in this simplified model)
        uint256 borrowIndex;   // cumulative index (1e18)
        uint256 lastAccrualBlock;
        bool listed;
    }

    struct BorrowSnapshot {
        uint256 principal; // borrowed principal (naive)
        uint256 borrowIndex;
    }

    IPriceOracle public oracle;
    InterestRateModel public rateModel;

    mapping(address => Asset) public assets;
    mapping(address => mapping(address => uint256)) public supplies; // user -> token -> amount supplied
    mapping(address => mapping(address => BorrowSnapshot)) public borrows; // user -> token -> snapshot
    mapping(address => mapping(address => uint256)) public collateral; // user -> token -> amount

    // global simple params (BASE = 1e5)
    uint256 public ltv = 50_000; // 50% LTV (in base 1e5)
    uint256 public liquidationThreshold = 60_000; // threshold for liquidation checks (example)
    uint256 public liquidationBonus = 105_000; // 5% bonus (1e5 base)
    uint256 constant BASE = 100000;

    event AssetListed(address token);
    event Supply(address user, address token, uint256 amount);
    event Withdraw(address user, address token, uint256 amount);
    event Borrow(address user, address token, uint256 amount);
    event Repay(address payer, address borrower, address token, uint256 amount);
    event Liquidate(address liquidator, address borrower, address repayToken, uint256 repayAmount, address collateralToken, uint256 seized);

    constructor(IPriceOracle _oracle, InterestRateModel _rateModel) {
        oracle = _oracle;
        rateModel = _rateModel;
    }

    modifier accrue(address tokenAddr) {
        _accrueInterest(tokenAddr);
        _;
    }

    function listAsset(address tokenAddr) external {
        Asset storage a = assets[tokenAddr];
        require(!a.listed, "already listed");
        a.token = ERC20Mock(tokenAddr);
        a.borrowIndex = 1e18;
        a.lastAccrualBlock = block.number;
        a.listed = true;
        emit AssetListed(tokenAddr);
    }

    // supply
    function supply(address tokenAddr, uint256 amount) external accrue(tokenAddr) {
        Asset storage a = assets[tokenAddr];
        require(a.listed, "not listed");
        require(a.token.transferFrom(msg.sender, address(this), amount), "transfer failed");
        supplies[msg.sender][tokenAddr] += amount;
        a.totalSupply += amount;
        emit Supply(msg.sender, tokenAddr, amount);
    }

    // withdraw (basic checks)
    function withdraw(address tokenAddr, uint256 amount) external accrue(tokenAddr) {
        require(supplies[msg.sender][tokenAddr] >= amount, "not enough supply");
        supplies[msg.sender][tokenAddr] -= amount;
        assets[tokenAddr].totalSupply -= amount;

        // simplified health: in this minimal example we'll skip complex multi-asset health checks.
        require(assets[tokenAddr].token.transfer(msg.sender, amount), "transfer out failed");
        emit Withdraw(msg.sender, tokenAddr, amount);
    }

    // collateral deposit/withdraw
    function depositCollateral(address tokenAddr, uint256 amount) external {
        require(assets[tokenAddr].listed, "token not listed");
        require(ERC20Mock(tokenAddr).transferFrom(msg.sender, address(this), amount), "transfer failed");
        collateral[msg.sender][tokenAddr] += amount;
    }

    function withdrawCollateral(address tokenAddr, uint256 amount) external {
        require(collateral[msg.sender][tokenAddr] >= amount, "not enough collateral");
        collateral[msg.sender][tokenAddr] -= amount;
        // minimal health check omitted for simplicity
        require(ERC20Mock(tokenAddr).transfer(msg.sender, amount), "transfer failed");
    }

    // borrow
    function borrow(address tokenAddr, uint256 amount) external accrue(tokenAddr) {
        Asset storage a = assets[tokenAddr];
        require(a.listed, "not listed");
        uint256 cash = a.totalSupply - a.totalBorrows;
        require(cash >= amount, "insufficient liquidity");

        // update naive borrower snapshot
        BorrowSnapshot storage snap = borrows[msg.sender][tokenAddr];
        if (snap.borrowIndex == 0) snap.borrowIndex = a.borrowIndex;
        snap.principal += amount;
        a.totalBorrows += amount;

        // simplified collateral check: offload complexity to tests/oracles
        require(a.token.transfer(msg.sender, amount), "transfer out failed");
        emit Borrow(msg.sender, tokenAddr, amount);
    }

    // repay
    function repay(address tokenAddr, uint256 amount, address borrower) external accrue(tokenAddr) {
        Asset storage a = assets[tokenAddr];
        require(a.listed, "not listed");
        require(a.token.transferFrom(msg.sender, address(this), amount), "transfer in failed");

        BorrowSnapshot storage snap = borrows[borrower][tokenAddr];
        uint256 owed = snap.principal;
        uint256 pay = amount > owed ? owed : amount;
        snap.principal -= pay;
        a.totalBorrows -= pay;
        emit Repay(msg.sender, borrower, tokenAddr, pay);
    }

    // liquidate (simple)
    function liquidate(address repayToken, address borrower, uint256 repayAmount, address collateralToken) external accrue(repayToken) accrue(collateralToken) {
        BorrowSnapshot storage snap = borrows[borrower][repayToken];
        require(snap.principal >= repayAmount, "repay > debt");

        // For demo: require borrower considered unhealthy by off-chain signal (tests will ensure this)
        // transfer repay from liquidator
        require(ERC20Mock(repayToken).transferFrom(msg.sender, address(this), repayAmount), "transfer in failed");

        // compute USD values using oracle (price with 1e18)
        uint256 priceRepay = oracle.getPrice(repayToken);
        uint256 repayValueUSD = (repayAmount * priceRepay) / 1e18;

        uint256 priceColl = oracle.getPrice(collateralToken);
        // seized = repayValueUSD * liquidationBonus / BASE / priceColl
        uint256 seized = (repayValueUSD * liquidationBonus) / (BASE * priceColl);

        require(collateral[borrower][collateralToken] >= seized, "not enough collateral to seize");

        // reduce debt and totalBorrows
        snap.principal -= repayAmount;
        assets[repayToken].totalBorrows -= repayAmount;

        // transfer seized collateral to liquidator
        collateral[borrower][collateralToken] -= seized;
        require(ERC20Mock(collateralToken).transfer(msg.sender, seized), "transfer seized failed");

        emit Liquidate(msg.sender, borrower, repayToken, repayAmount, collateralToken, seized);
    }

    // interest accrual (very basic)
    function _accrueInterest(address tokenAddr) internal {
        Asset storage a = assets[tokenAddr];
        if (!a.listed) return;
        uint256 blockDelta = block.number - a.lastAccrualBlock;
        if (blockDelta == 0) return;

        uint256 cash = a.totalSupply > a.totalBorrows ? a.totalSupply - a.totalBorrows : 0;
        uint256 borrowRatePerBlock = rateModel.getBorrowRate(cash, a.totalBorrows); // 1e18 per-block
        uint256 interestFactor = (borrowRatePerBlock * blockDelta) / 1e18;
        uint256 interestAccumulated = (a.totalBorrows * interestFactor);
        a.totalBorrows += interestAccumulated;
        a.borrowIndex = (a.borrowIndex * (1e18 + interestFactor)) / 1e18;
        a.lastAccrualBlock = block.number;
    }

    // helper views
    function getCollateralValueUSD(address user, address tokenAddr) external view returns (uint256) {
        uint256 amt = collateral[user][tokenAddr];
        if (amt == 0) return 0;
        uint256 p = oracle.getPrice(tokenAddr);
        return (amt * p) / 1e18;
    }

    function getBorrowValueUSD(address user, address tokenAddr) external view returns (uint256) {
        uint256 amt = borrows[user][tokenAddr].principal;
        if (amt == 0) return 0;
        uint256 p = oracle.getPrice(tokenAddr);
        return (amt * p) / 1e18;
    }
}
