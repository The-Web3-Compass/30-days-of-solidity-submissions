// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract aToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("aToken", "ATK") {
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }
}

// This contract is a simple ERC20 token using OpenZeppelin's ERC20 implementation.