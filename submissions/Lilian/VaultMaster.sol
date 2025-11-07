// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";

contract VaultMaster is ownable{
    event DepositSuccessful (address indexed accout,uint256 value);//有人向合约发送ETH时发送
    event WithdrawSuccessful(address indexed recipient,uint256 value);//有人提取ETH时发送

    function getbalance() public view returns(uint256) {
        return address(this).balance;//返回合约持有的ETH值
    }

    function deposit() public payable {
        require(msg.value>0,"Enter a valid amount");//用requie要求某人发送》0
        emit DepositSuccessful(msg.sender, msg.value);//记录发送者的地址和数量
    }
    function withdraw(address _to,uint256 _amount)public onlyowner{
        require(_amount<=getbalance(),"Insufficent balance");//检查是否有足够的ETH

        (bool success,)=payable (_to).call{value:_amount}("");
        require(success,"Transfer Failed");

        emit WithdrawSuccessful(_to, _amount);//来记录转账成功

    }
}
