// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal IERC20 Interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// Minimal ERC20 Implementation
contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= value, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - value;
        }
        _balances[to] += value;
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += value;
        _balances[account] += value;
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= value, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - value;
        }
        _totalSupply -= value;
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = value;
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= value, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - value);
            }
        }
    }
}

// Minimal ReentrancyGuard
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// Minimal Ownable
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Minimal AggregatorV3Interface
interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// Core Contract
contract SimpleStablecoin is ERC20, ReentrancyGuard, Ownable {
    AggregatorV3Interface internal priceFeed;
    uint256 public constant COLLATERAL_RATIO = 150; 
    mapping(address => uint256) public collateralDeposited;

    constructor(address _priceFeedAddress) ERC20("StableUSD", "SUSD") {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function depositCollateral() external payable {
        collateralDeposited[msg.sender] += msg.value;
    }

    function mintStablecoin(uint256 amountToMint) external nonReentrant {
        uint256 currentEthValue = getCollateralValueInUsd(msg.sender);
        uint256 currentDebt = balanceOf(msg.sender);
        
        uint256 maxMintable = (currentEthValue * 100) / COLLATERAL_RATIO;
        require(currentDebt + amountToMint <= maxMintable, "Not enough collateral!");

        _mint(msg.sender, amountToMint);
    }

    function burnStablecoin(uint256 amountToBurn) external nonReentrant {
        _burn(msg.sender, amountToBurn);
    }

    function withdrawCollateral(uint256 amount) external nonReentrant {
        require(collateralDeposited[msg.sender] >= amount, "Insufficient collateral");
        uint256 currentDebt = balanceOf(msg.sender);
        
        uint256 remainingCollateral = collateralDeposited[msg.sender] - amount;
        uint256 remainingValue = (remainingCollateral * getEthPrice()) / 1e18; 

        uint256 requiredCollateralValue = (currentDebt * COLLATERAL_RATIO) / 100;

        require(remainingValue >= requiredCollateralValue, "Cannot withdraw, health factor too low");

        collateralDeposited[msg.sender] -= amount;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function getEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price) * 1e10; 
    }

    function getCollateralValueInUsd(address user) public view returns (uint256) {
        uint256 ethAmount = collateralDeposited[user];
        uint256 ethPrice = getEthPrice();
        return (ethAmount * ethPrice) / 1e18;
    }
}
