// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20{

    constructor(uint count) ERC20("MyToken","MK"){
        _mint(msg.sender , count);
    }

}