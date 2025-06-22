// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;
import "./Day11-Ownable.sol";


contract VaultMaster is Ownable {
    /**
    Inheritance helps you:
    Avoid writing the same logic in multiple places
    Split your code into smaller, focused pieces        
    Reuse important features like access control or utility functions
    Make your contracts easier to update and maintain

    Also you can use OpenZeppelin,that can make code simpler and fewer bugs.
    */

    event DepositSuccessful(address indexed account,uint256 amount);
    event WithdrawSuccessful(address indexed recipient,uint256 amount);

    function getBalance() public view onlyOwner returns(uint256){
        return address(this).balance;
    }

    function deposit() public payable {
        require(msg.value > 0,"Invaild amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    function withdraw(address _to,uint256 _amount) public onlyOwner {
        require(_amount > 0 ,"Invaild amount");
        require(_to != address(0),"Invaild address");

        (bool success, ) = payable(_to).call{value:_amount}("");
        require(success, "Withdraw Failed");

        emit WithdrawSuccessful(_to, _amount);

    }




}