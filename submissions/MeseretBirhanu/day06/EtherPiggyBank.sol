// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EtherPiggyBank{

    struct savingAcc{
        string username;
        uint256 goal;
        uint256 currentAmount;
        bool goalReached;

    }

    mapping (address => uint256) public accounts;
    mapping (address => savingAcc) public savings;

    event  deposited(address _addr , uint256 amount);
    event  withdrawn(address _addr , uint256 amount);


    function deposit() public payable  {
        require(msg.value > 0, "invalid amount");
        accounts[msg.sender] += msg.value;    
        emit deposited(msg.sender , msg.value);

    }
    
    
    function withdraw(uint256 _amount) public payable  {
        require(_amount > 0, "invalid amount");
        require(_amount < accounts[msg.sender] , "insufficient balance");
        accounts[msg.sender] -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success , " withdrawing failed");
        emit withdrawn(msg.sender , _amount);

    }

    // saving some , no withdrawal untill goal met
    function createSavingAcc(string calldata _name , uint256 _goal) public {
        require(_goal > 0 , "invalid amount");
        savingAcc  memory newSavingAcc = savingAcc(_name , _goal , 0 , false);
        savings[msg.sender] = newSavingAcc;

    }
    function depositToSavings() public payable{
        require(msg.value > 0 , "invalid amount");
        savings[msg.sender].currentAmount += msg.value;
        if(savings[msg.sender].currentAmount >= savings[msg.sender].goal ){
            savings[msg.sender].goalReached = true;
        }

    }
    
    function withdrawFromSavings(uint256 _amount) public payable {
        require(_amount > 0 , "invalid amount");
        require(savings[msg.sender].goalReached, "goal not yet met!" );
        savings[msg.sender].currentAmount -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success , "withdrawal failed");

    }
}