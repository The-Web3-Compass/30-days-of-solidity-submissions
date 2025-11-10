// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// 跟踪谁是所有者，并使用onlyOwner修饰符限制操作权限
contract Ownable {

    // 存储合约所有者（部署合约者）的地址
    address private owner;

    // 事件：记录合约所有权转移，indexed关键字过滤日志（可以根据前所有者/新所有者的地址筛选出所有事件）
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // 构造函数：将部署者设置为初始所有者；并通过emit触发事件：记录所有者变更
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // 修饰符：只有所有者可以调用
    modifier onlyOwner() {
         require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    // 返回所有者地址，pulic-所有人都可以查看
    function ownerAddress() public view returns (address) {
        return owner;
    }

    // 所有权转移，接收新所有者地址（参数）
    function transferOwnership(address _newOwner) public onlyOwner {
       require (_newOwner !=address(0), "Invalid address"); 
        address previous = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previous, _newOwner);

    }
}