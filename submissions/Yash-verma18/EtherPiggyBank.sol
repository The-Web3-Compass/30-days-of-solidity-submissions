//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {
  
    mapping (address => uint256) public addressToBalance;
    mapping(address => uint256) public lastWithdrawTime;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);


    function getPiggyBankBalance() public view returns (uint256){
        return address(this).balance;
    }

    receive() external payable { 
        addressToBalance[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit must be greater than 0");
        addressToBalance[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }


    function withdraw(uint256 amount) public  {
       require (addressToBalance[msg.sender] >= amount, "Not enough money");
       require(block.timestamp - lastWithdrawTime[msg.sender] > 1 days, "You can only withdraw once a day");

       addressToBalance[msg.sender] -= amount;
       payable(msg.sender).transfer(amount);
       lastWithdrawTime[msg.sender] = block.timestamp;
       emit Withdrawn(msg.sender, amount);
    }

}