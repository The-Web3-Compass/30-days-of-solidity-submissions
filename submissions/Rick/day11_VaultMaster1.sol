// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultMaster is Ownable   {
    
    // 部署合约时 向OpenZeppelin 传递初始拥有者
    constructor() Ownable(msg.sender) {}


    function deposit() public payable {
        
    }

    function withdraw(address _to , uint256 _amount) public payable onlyOwner{

        require(_amount <= address(this).balance , unicode"转账不能超过余额");
    
        (bool success ,) = payable(_to).call{ value : _amount}("");

        require(success, unicode"转账失败");

    }

    // override 说明此处重写了父合约的方法
    // override和virtual 必须同时存在
    function foo() public pure  override  returns (uint256){
        return 3;
    }
}