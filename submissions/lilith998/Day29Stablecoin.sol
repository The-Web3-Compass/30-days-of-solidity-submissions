// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title StableCoin
 * @dev A basic fiat-collateralized stablecoin pegged to $1 USD
 */
contract StableCoin is ERC20, Ownable {

    constructor() ERC20("StableCoin", "STC") Ownable(msg.sender) {
        
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    uint256 public collateralRatio = 100; // 100% collateralized
    uint256 public price = 1e18; // Target price in USD (1 USD)

    IERC20 public collateralToken; // e.g., USDC or DAI

    /**
     * @dev Mints stablecoins by depositing collateral
     * @param amount Amount of collateral to deposit
     */
    function mint(uint256 amount) external {
        require(
            collateralToken.transferFrom(msg.sender, address(this), amount),
            "Collateral transfer failed"
        );

        // Mint equivalent stablecoins (1:1 peg assumed)
        _mint(msg.sender, amount);
    }

    /**
     * @dev Burns stablecoins and returns collateral
     * @param amount Amount of stablecoins to burn
     */
    function redeem(uint256 amount) external {
        _burn(msg.sender, amount);

        require(
            collateralToken.transfer(msg.sender, amount),
            "Collateral return failed"
        );
    }

    /**
     * @dev Owner can update collateral ratio for dynamic peg (future use)
     */
    function setCollateralRatio(uint256 _ratio) external onlyOwner {
        require(_ratio <= 100, "Max ratio is 100%");
        collateralRatio = _ratio;
    }
}
