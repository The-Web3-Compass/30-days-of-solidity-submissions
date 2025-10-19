// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    uint8 public constant override decimals = 18;  // Explicit and immutable

    constructor(uint256 initialSupply) ERC20("MyToken", "MTK") {
        require(initialSupply * 10 ** decimals <= type(uint256).max, "Initial supply too large");
        _mint(msg.sender, initialSupply * 10 ** decimals);
    }
}