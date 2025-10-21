// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
    
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(recipient != address(0), "Transfer to zero address");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "Approve to zero address");
        
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");
        require(balanceOf[sender] >= amount, "Insufficient balance");
        require(allowance[sender][msg.sender] >= amount, "Allowance exceeded");
        
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        allowance[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to zero address");
        
        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Burn from zero address");
        require(balanceOf[account] >= amount, "Insufficient balance");
        
        balanceOf[account] -= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}


contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Stablecoin is ERC20, Ownable, ReentrancyGuard {

    struct Collateral {
        address token;
        address priceFeed; 
        uint256 collateralFactor; 
        uint256 liquidationFactor; 
        uint8 tokenDecimals; 
    }

    struct Position {
        mapping(address => uint256) collateralAmount; 
        uint256 debt; 
    }

    Collateral[] public collaterals;
    mapping(address => Position) public positions;
    uint256 public constant LIQUIDATION_BONUS = 105; 
    uint256 public constant LIQUIDATION_PENALTY = 95; 
    uint256 public constant MIN_COLLATERAL_RATIO = 150;

    constructor() ERC20("PeggedUSD", "PUSD", 18) {
        _mint(msg.sender, 1000 * 10 ** decimals);
    }

    function addCollateral(
        address token, 
        address priceFeed, 
        uint256 collateralFactor,
        uint256 liquidationFactor,
        uint8 tokenDecimals
    ) external onlyOwner {
        require(collateralFactor >= MIN_COLLATERAL_RATIO, "Collateral factor too low");
        require(liquidationFactor < collateralFactor, "Liquidation factor too high");
        
        collaterals.push(Collateral({
            token: token,
            priceFeed: priceFeed,
            collateralFactor: collateralFactor,
            liquidationFactor: liquidationFactor,
            tokenDecimals: tokenDecimals
        }));
    }

    function depositCollateral(uint256 collateralId, uint256 amount) external nonReentrant {
        require(collateralId < collaterals.length, "Invalid collateral ID");
        Collateral storage collateral = collaterals[collateralId];

        ERC20(collateral.token).transferFrom(msg.sender, address(this), amount);
    
        positions[msg.sender].collateralAmount[collateral.token] += amount;
        emit CollateralDeposited(msg.sender, collateralId, amount);
    }
 
    function withdrawCollateral(uint256 collateralId, uint256 amount) external nonReentrant {
        require(collateralId < collaterals.length, "Invalid collateral ID");
        Collateral storage collateral = collaterals[collateralId];
        
        require(positions[msg.sender].collateralAmount[collateral.token] >= amount, "Insufficient collateral");
  
        positions[msg.sender].collateralAmount[collateral.token] -= amount;

        require(getCollateralRatio(msg.sender) >= MIN_COLLATERAL_RATIO, 
            "Collateral ratio too low");

        ERC20(collateral.token).transfer(msg.sender, amount);
        emit CollateralWithdrawn(msg.sender, collateralId, amount);
    }
    function mint(uint256 amount) external nonReentrant {
        uint256 ratio = getCollateralRatio(msg.sender);
        require(ratio >= MIN_COLLATERAL_RATIO, "Insufficient collateral");
        positions[msg.sender].debt += amount;
        _mint(msg.sender, amount);
        emit StablecoinMinted(msg.sender, amount);
    }
    
    function repay(uint256 amount) external nonReentrant {
        require(positions[msg.sender].debt >= amount, "Debt too low");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        positions[msg.sender].debt -= amount;
        
        _burn(msg.sender, amount);
        emit StablecoinRepaid(msg.sender, amount);
    }
  
function liquidate(address user, uint256 collateralId, uint256 debtAmount) external nonReentrant {
    require(collateralId < collaterals.length, "Invalid collateral ID");
    Collateral storage collateral = collaterals[collateralId];
   
    uint256 ratio = getCollateralRatio(user);
    require(ratio < collateral.liquidationFactor, "Position not liquidatable");
    
    uint256 maxDebt = positions[user].debt;
    if (debtAmount > maxDebt) {
        debtAmount = maxDebt;
    }
    

    uint256 liquidationBonus = (debtAmount * LIQUIDATION_BONUS) / 100;
    
    uint256 tokenValue = getTokenValue(collateral.token);
    require(tokenValue > 0, "Token value is zero");
    
    uint256 collateralAmount = (debtAmount * LIQUIDATION_PENALTY) / 100;
    collateralAmount = collateralAmount / tokenValue;
    
    require(positions[user].collateralAmount[collateral.token] >= collateralAmount, 
        "Insufficient collateral to liquidate");

    positions[user].collateralAmount[collateral.token] -= collateralAmount;
    positions[user].debt -= debtAmount;

    ERC20(collateral.token).transfer(msg.sender, collateralAmount + liquidationBonus);
    
    emit PositionLiquidated(user, msg.sender, collateralId, debtAmount, collateralAmount);
}

    function getCollateralValue(address user) public view returns (uint256) {
        uint256 totalValue = 0;
        
        for (uint256 i = 0; i < collaterals.length; i++) {
            Collateral storage collateral = collaterals[i];
            uint256 amount = positions[user].collateralAmount[collateral.token];
            
            if (amount > 0) {
                uint256 tokenValue = getTokenValue(collateral.token);
                totalValue += amount * tokenValue;
            }
        }
        
        return totalValue;
    }
    
    function getTokenValue(address token) internal view returns (uint256) {
        for (uint256 i = 0; i < collaterals.length; i++) {
            if (collaterals[i].token == token) {
                Collateral storage collateral = collaterals[i];
                AggregatorV3Interface priceFeed = AggregatorV3Interface(collateral.priceFeed);
                (, int256 answer,,,) = priceFeed.latestRoundData();
                
                require(answer > 0, "Invalid price");
                
                return uint256(answer) * (10 ** (18 - priceFeed.decimals()));
            }
        }
        
        return 0;
    }
    
    function getCollateralRatio(address user) public view returns (uint256) {
        uint256 totalCollateralValue = getCollateralValue(user);
        if (totalCollateralValue == 0) return 0;
        
        return (totalCollateralValue * 100) / positions[user].debt;
    }
    
    event CollateralDeposited(address indexed user, uint256 indexed collateralId, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 indexed collateralId, uint256 amount);
    event StablecoinMinted(address indexed user, uint256 amount);
    event StablecoinRepaid(address indexed user, uint256 amount);
    event PositionLiquidated(
        address indexed user, 
        address indexed liquidator, 
        uint256 indexed collateralId, 
        uint256 debtAmount, 
        uint256 collateralAmount
    );
}
