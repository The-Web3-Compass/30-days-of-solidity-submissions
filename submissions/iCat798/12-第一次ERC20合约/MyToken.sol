// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//用OpenZeppelin 创建自己的代币
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 

contract MyToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("MyToken", "MTK") {  //设置代币基本信息（名称,符号）
        _mint(msg.sender, initialSupply * 10 ** decimals());      //_mint OZ的内部函数，用于增加代币供应量，并分配给指定地址
    }
}

