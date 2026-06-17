// SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

// You can view this file in github and cite this file from github.
import "@openzeppelin/contracts/access/Ownable.sol";


// // import Ownable contract from other profile
// import "./Ownable.sol";

// "contract VaultMaster is Ownable" : that means "VaultMaster" automatically has all the functions, variables and modifiers from "Ownable".
contract VaultMaster is Ownable{
    event DepositSuccessful(address indexed account,uint256 value);
    event WithdrawSuccessful(address indexed reciepient,uint256 value);
    
    // In the Ownable.sol from "openzeppelin", it sets the initial owner in the constructor. So pass the initial owner in the constructor of this contract.
    constructor() Ownable(msg.sender){

    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function deposit() public payable{
        require(msg.value>0,"Enter a valid amount");
        emit DepositSuccessful(msg.sender,msg.value);
    }

    function withdraw(address _to,uint256 _amount) public onlyOwner{
        require(_amount<=getBalance(),"Insufficient balance");
        (bool success,)=payable(_to).call{value:_amount}("");
        require(success,"Transfer failed");
        emit WithdrawSuccessful(_to,_amount);
    }
}





