// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CoolCoinERC20 is ERC20 {

    // 直接继承 openzeppelin 的 ERC20 合约
    constructor(uint256 initialSupply) ERC20("CoolCoin", "COOL") {
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }
}