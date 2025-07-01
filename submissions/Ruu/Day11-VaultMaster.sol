//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract VaultMaster is Ownable{

    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawalSuccessful(address indexed recipient, uint256 value);

    function Deposit() public payable{
        require(msg.value > 0, "Enter a valid amount");
        emit DepositSuccessful(msg.sender, msg.value);

    }

    function GetBalance() public view returns(uint256){
        return address(this).balance;

    }

    function Withdraw(address _to_, uint256 _amount_) public OnlyOwner{
        require( _amount_ <= GetBalance(), "Insufficient Balance");
        (bool success,) = payable(_to_).call{value:_amount_}("");
        require(success, "Transfer failed");
        emit WithdrawalSuccessful(_to_, _amount_);
        
    }
}
