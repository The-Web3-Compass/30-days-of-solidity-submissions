// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleStablecoin is ERC20 {
    address public collateralToken;
    
    uint256 public collateralizationRatio = 150;
    
    mapping(address => uint256) public collateralBalance;
    
    event Minted(address indexed user, uint256 stablecoinAmount, uint256 collateralAmount);
    event Redeemed(address indexed user, uint256 stablecoinAmount, uint256 collateralAmount);

    constructor(address _collateralToken) 
        ERC20("Simple USD Stablecoin", "sUSD") 
    {
        collateralToken = _collateralToken;
    }

    function mint(uint256 collateralAmount, uint256 stablecoinAmount) external {
        require(collateralAmount > 0, "抵押品数量必须大于0");
        require(stablecoinAmount > 0, "稳定币数量必须大于0");
        

        uint256 requiredCollateral = (stablecoinAmount * collateralizationRatio) / 100;
        require(collateralAmount >= requiredCollateral, "抵押品不足");
   
        collateralBalance[msg.sender] += collateralAmount;
        
        _mint(msg.sender, stablecoinAmount);
        
        emit Minted(msg.sender, stablecoinAmount, collateralAmount);
    }

    function redeem(uint256 stablecoinAmount) external {
        require(stablecoinAmount > 0, "稳定币数量必须大于0");
        require(balanceOf(msg.sender) >= stablecoinAmount, "稳定币余额不足");
        
        uint256 collateralToReturn = (stablecoinAmount * 100) / collateralizationRatio;
        require(collateralBalance[msg.sender] >= collateralToReturn, "抵押品余额不足");
        
        _burn(msg.sender, stablecoinAmount);
        
        collateralBalance[msg.sender] -= collateralToReturn;
        
        emit Redeemed(msg.sender, stablecoinAmount, collateralToReturn);
    }

    function getMaxMintable(uint256 collateralAmount) public view returns (uint256) {
        return (collateralAmount * 100) / collateralizationRatio;
    }

    function getCollateralBalance(address user) public view returns (uint256) {
        return collateralBalance[user];
    }
}