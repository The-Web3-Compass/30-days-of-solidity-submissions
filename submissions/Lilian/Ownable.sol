// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ownable{
    address private  owner;
    event Ownershiptransferred (address indexed previousOwner,address indexed newOwner);//触发事件

    constructor(){
        owner=msg.sender;//部署初始者
        emit Ownershiptransferred(address(0), msg.sender);
    }

    modifier onlyowner(){
        require(msg.sender == owner,"only owner can perform this action");
        _;//确保只有调用者可以使用
    }

    function ownerAddress()public view returns (address){
        return owner;//提供一个公共函数，检查所有者
    }

    function transferrownership (address _newOwner)public onlyowner{
        require(_newOwner !=address(0),"Invalid address");//检查地址是否有效
        address previousOwner = owner;//存储在previous里面
        owner=_newOwner;
        emit Ownershiptransferred(previousOwner,_newOwner);
    }
}