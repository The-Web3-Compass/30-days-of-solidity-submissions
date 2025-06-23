// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyFirstToken is ERC20 {
    // Constructor initializes the token with a name, symbol, and initial supply
    constructor(uint256 initialSupply) ERC20("MyFirstToken", "MFT") {
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }
}
