//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Ownable {
    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);     
    //定义一个事件（event），用于在区块链上记录日志

    constructor() {    
    //定义构造函数，在合约部署时自动执行一次，用来初始化数据

        owner = msg.sender;     
        //把部署合约的人设置为 owner

        emit OwnershipTransferred(address(0), msg.sender);     
        //触发事件 OwnershipTransferred，记录从“零地址”转移到当前部署者的过程

    }

modifier onlyOwner() {     
//定义一个函数修饰器，用于限制某些函数只能由合约拥有者调用

    require(msg.sender == owner, "Only owner can perform this action");     
    //判断当前调用者是否为所有者，如果不是，则交易回退

    _;     
    //表示“被修饰的函数体将在这里执行
}

function ownerAddress() public view returns (address) {     
//定义一个公开函数，用来读取当前的所有者地址

    return owner;     
    //返回状态变量 owner 的值
}

function transferOwnership(address _newOwner)public onlyOwner{     
//定义一个函数，用来转移合约的所有权

    require(_newOwner != address(0), "Invaild address");     
    //防止把所有者设置成零地址

    address previous = owner;     
    //把当前 owner 先存入一个本地变量 previous，以便后面事件记录使用

    owner = _newOwner;     
    //把新的地址 _newOwner 设置为合约的拥有者

    emit OwnershipTransferred(previous, _newOwner);     
    //触发事件 OwnershipTransferred，记录“所有者从 previous 改为 _newOwner”
}    

}