// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Stablecoin.sol
 * @dev A simplified collateral-backed stablecoin example
 * Concepts:
 * - ERC20 basics
 * - Collateral deposits
 * - Minting/burning stablecoins
 * - Simulated peg stability (1 stable = 1 ETH worth)
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Stablecoin is ERC20, Ownable {
    // mapping of user collateral balances (ETH)
    mapping(address => uint256) public collateralBalance;

    // collateralization ratio (e.g., 150% = 1.5 * minted amount)
    uint256 public constant COLLATERAL_RATIO = 150; // 150%
    uint256 public constant PEG = 1e18; // 1 stable = 1 ETH

    constructor() ERC20("CompassUSD", "cUSD") Ownable(msg.sender) {}

    /**
     * @dev Deposit ETH as collateral to mint stablecoins
     */
    function depositAndMint() external payable {
        require(msg.value > 0, "No ETH sent");

        // Calculate mintable amount = (ETH value / 1.5)
        uint256 mintAmount = (msg.value * 100) / COLLATERAL_RATIO;
        collateralBalance[msg.sender] += msg.value;

        _mint(msg.sender, mintAmount);
    }

    /**
     * @dev Burn stablecoins to withdraw collateral
     */
    function burnAndWithdraw(uint256 burnAmount) external {
        require(balanceOf(msg.sender) >= burnAmount, "Not enough balance");

        // Calculate withdrawable collateral
        uint256 withdrawAmount = (burnAmount * COLLATERAL_RATIO) / 100;

        require(
            collateralBalance[msg.sender] >= withdrawAmount,
            "Not enough collateral"
        );

        _burn(msg.sender, burnAmount);
        collateralBalance[msg.sender] -= withdrawAmount;

        payable(msg.sender).transfer(withdrawAmount);
    }

    /**
     * @dev Simulate price stability check (dummy logic)
     */
    function checkPeg() external pure returns (string memory) {
        // In real stablecoins, this would use oracles to check market price.
        return "Peg stable at 1 cUSD = 1 USD";
    }

    receive() external payable {}
}
