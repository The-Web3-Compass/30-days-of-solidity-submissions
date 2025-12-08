// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyFirstToken is ERC20 {
    uint constant _initialSupply = 1000 * (10 ** 8);

    constructor() ERC20("My First Token", "MFG"){
        _mint(msg.sender, _initialSupply);
    }

}