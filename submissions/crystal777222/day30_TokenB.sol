// SPDX-License_Identifier: MIT 

pragma solidity ^0.8.20;

import "openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenB is ERC20 {

    constructor() ERC20 ("TokenB", "TKB") {
        _mint(msg.sender, 1000000 * 10 ** decimals()); // mint 1 million tokens to you
    }
}
