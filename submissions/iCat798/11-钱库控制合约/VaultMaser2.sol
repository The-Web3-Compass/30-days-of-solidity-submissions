// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;


// 导入官方 OpenZeppelin 版本合约
import "@openzeppelin/contracts/access/Ownable.sol";


// 让用户存入ETH的金库，但只允许所有者可以提取资金
contract VaultMaster is Ownable{


    event DepositSuccessful(address indexed account, uint256 value);     // 存钱成功，记录存钱账户和数额
    event WithdrawSuccessful(address indexed reciepient, uint256 value); // 取钱成功，记录取钱账户和数额

    // 使用 OpenZeppelin 的构造函数将部署者设置为所有者
    constructor() Ownable(msg.sender) {}
    
    // 返回合约当前持有的ETH数量
    function getBalance()public view returns(uint256){
        return address(this).balance;
    }

    // 允许任何人向合约存入（发送） ETH
    function deposit()public payable{
        require(msg.value >0, "Enter a valid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    // 只允许合约所有者从合约中提取ETH转账到另一个账户
    function withdraw(address _to, uint256 _amount) public onlyOwner {
        require(_amount <= getBalance(), "Insufficient balance");
        (bool success , ) = payable(_to).call{value: _amount}(""); // 将指定数量发送到给定地址
        require(success, "Transfer Failed");
        emit WithdrawSuccessful(_to, _amount); // 如果转账成功，我们发出 WithdrawSuccessful 事件来记录该操作。
        
    }

}

// 地址1:0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// 地址2:0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2