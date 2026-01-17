//SPDX-License-Identifier:MIT
//pragma solidity ^0.8.0;
pragma solidity ^0.8.20;

contract Ownable{
    //定义一个主理人
    address private owner;

    //设置事件，发布主理人更改信息
    event ownershiptransferred(address indexed previousOwner,address indexed newOwner);

    //构造函数初始化合约基础信息，触发第一次事件
    constructor(){
        owner=msg.sender;
        emit ownershiptransferred(address(0), msg.sender);
    }

    //修饰符小警察限制只有主理人可操作
    modifier onlyOwner{
        require (msg.sender==owner,"only owner can perform this acion.");
        _;
    }
//正式操作
    //1、查询当前主理人
    function ownerAddress()public view returns(address){
        return owner;
    }
    //2、转换主理人
    function transferOwner(address _newOwner)public onlyOwner{
        require(_newOwner !=address(0),"the new owner address can not be zero address.");
        require(_newOwner !=owner,"the new owner address can not be same as old owner address.");
        emit ownershiptransferred(owner, _newOwner);
        owner=_newOwner;       
    }


}
