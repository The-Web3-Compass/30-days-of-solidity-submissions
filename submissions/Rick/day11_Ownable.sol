// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable{
    
    address private owner;

    constructor (){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this action");
         _; 
    }

    // 事件 设置owner成功
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    // 转账成功
    event WithdrawSuccessful(address indexed recipient, uint256 value);

    // 获取owner
    function ownerAddress() public view returns (address) {
        return owner;
    }

    // 转移owner
    function changeOwner(address _owner) public onlyOwner {
        require(_owner != address(0), unicode"不允许转给地址零");

        emit OwnershipTransferred(owner,_owner);
        owner = _owner;
    }

    //virtual  作为父合约中 可被子合约修改的方法
    function foo() public pure virtual returns (uint256){
        return 1;
    }
}