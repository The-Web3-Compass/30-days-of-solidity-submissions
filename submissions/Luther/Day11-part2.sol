//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Day11-part1.sol";

contract VaultMaster is Ownable {     
//定义合约 VaultMaster，并且继承 Ownable（因此可以使用 onlyOwner、owner 状态等）

    event DepositSuccessful(address indexed account, uint256 value);     
    //声明事件 DepositSuccessful，用于在链上发日志记录存款行为（便于前端或监听器追踪）

    event WithdrawSuccessful(address indexed recipient, uint256 value);     
    //声明事件 WithdrawSuccessful，用于记录提款（取款）成功的日志

    function getBalance() public view returns (uint256) {    
    //定义一个公开函数 getBalance，返回当前合约的 ETH 余额

        return address(this).balance;     
        //返回当前合约地址的余额（单位 wei）
}

    function deposit() public payable {
    //定义公开的 deposit 函数，允许外部发送以太币到合约（接收并记录存款事件）

        require(msg.value > 0, "Enter a valid amount");     
        //检查调用时发送的 ETH 是否大于 0；若为 0，则回退并返回错误信息

        emit DepositSuccessful(msg.sender, msg.value);     
        //触发 DepositSuccessful 事件，记录谁（msg.sender）存了多少（msg.value）
    }

    function withdraw(address _to, uint256 _amount) public onlyOwner {     
        //定义 withdraw 函数，由合约拥有者调用以将 _amount wei 发送到 _to 地址

        require(_amount <= getBalance(), "Insufficient balance");     
        //检查请求提款的金额不超过合约余额，若超出则 revert 并给出错误信息

        (bool success, ) = payable(_to).call{value: _amount}("");     
        //把 _amount wei 发送到 _to 地址，并捕获是否成功（success），采用低级 call

        require(success, "Transfer Failed");    
         //如果 call 返回 false（代表转账失败），则回退并显示错误信息

        emit WithdrawSuccessful(_to, _amount);     
        //触发 WithdrawSuccessful 事件，记录取款目标与金额，便于链上审计与前端展示


}

}