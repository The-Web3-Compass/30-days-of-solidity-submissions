// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Token A
contract TokenA is ERC20 {

    constructor() ERC20("Token A", "TKA") {
        _mint(msg.sender, 1000000 * 10 ** decimals()); 
    }
}