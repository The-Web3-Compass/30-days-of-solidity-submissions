//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

//import "./ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract VaultMaster is Ownable{
    //vaultmaster inherits from Ownable
    // it has all the function, variable, modifier from Ownable

    constructor()Ownable(msg.sender){} //pass the initial owner for openzeppelin version

    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawalSuccessful(address indexed recipient, uint256 value);

    function deposit() public payable {
        require(msg.value >0,"Amount has to be greater than 0");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    function getBalance()public view returns(uint256){
        return address(this).balance;
    }

    function withdraw(address _to, uint256 _amount) public onlyOwner{
        require(_amount<= getBalance(),"Not enough money");
        
        (bool success,) =payable(_to).call{value: _amount}("");
        require(success,"Transfer failed");
        emit WithdrawalSuccessful(_to, _amount);
    }
}