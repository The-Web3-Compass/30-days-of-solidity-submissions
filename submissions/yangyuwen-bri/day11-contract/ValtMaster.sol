// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;
import "./Ownable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol"; //直接调用openzeppelin库

contract ValtMaster is Ownable{

    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);
    
    //把部署此合约的人设置为owner
    //constructor() Ownable(msg.sender){}

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function deposit() public payable{
        //允许任何人将ETH发送到合约中，记录发送者地址和数量
        require(msg.value > 0, "invalid amount");
        emit DepositSuccessful(msg.sender, msg.value);

    }

    function withdraw(address _to, uint256 _amount) public onlyOwner{
        //仅限所有者提取ETH 到指定地址 用.call()发送
        require(_amount <= getBalance(), "insufficient balance");
        
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "withdraw failed");

        emit WithdrawSuccessful(_to, _amount);

    }
}