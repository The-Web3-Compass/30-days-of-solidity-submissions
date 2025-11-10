// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(
        string memory n,
        string memory s,
        uint256 supply
    ) ERC20(n, s) {
        _mint(msg.sender, supply);
    }
}
