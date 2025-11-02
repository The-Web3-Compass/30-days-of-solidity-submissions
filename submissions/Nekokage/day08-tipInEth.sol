//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public owner;
    
    uint256 public totalTips;
    
    mapping(address => uint256) public userTips;
    
    constructor() {
        owner = msg.sender; // 设置部署者为拥有者
    }
    
     modifier onlyOwner() {
        require(msg.sender == owner,  "只有合约拥有者可以执行此操作");
        _;
    }
    
    // 接收ETH小费的函数
    function sendTip() public payable {
        require(msg.value > 0, "小费金额必须大于0");
        
        // 记录用户给的小费
        userTips[msg.sender] += msg.value;
        totalTips += msg.value;
    }
    
    // 提取所有小费（只有拥有者可以调用）
    function withdrawTips() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "没有小费可提取");
        
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "转账失败");
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getUserTipAmount(address user) public view returns (uint256) {
        return userTips[user];
    }
    
    // 转移拥有权
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "无效地址");
        owner = newOwner;
    }
    
    receive() external payable {
        userTips[msg.sender] += msg.value;
        totalTips += msg.value;
    }
}