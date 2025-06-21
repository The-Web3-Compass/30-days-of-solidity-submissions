//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Myfirsttoken is ERC20{
    constructor (uint256 initialSupply) ERC20("Herstory","HER"){

        _mint(msg.sender, initialSupply*10 ** decimals());
        //  //_mint 是 ERC20 合约中的内部函数，用于“铸造”新代币。

        //基于 OpenZeppelin 或标准实现的 ERC20），decimals 是一个 函数（function）
      
//两行代码的作用是：在部署合约时，设置代币的名称和符号，并把指定数量的代币全部分配给合约创建者。
    }

}