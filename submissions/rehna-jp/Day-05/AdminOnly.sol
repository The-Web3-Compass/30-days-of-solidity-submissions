// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract adminOnly{
    address admin;
    uint[] treasuryChest;
    uint treasureBalance;
    mapping (address => uint) allowance;
    mapping (address => bool) hasWithdrawn;

    constructor(){
        admin = msg.sender;
    }

    modifier onlyAdmin{
        require(msg.sender == admin, "Access denied, You are not an Admin");
        _;
    }

    modifier onlyApproved{
        require((allowance[msg.sender]) > 0 , "You have not been given an allowance yet");
        _;
    }

    event withdrawal(address indexed user, uint amount);


    function addToTreasury(uint amount) external onlyAdmin{
         treasuryChest.push(amount);
         treasureBalance += amount;
    }


    function withdrawTreasure(uint amount) external onlyApproved{ 
           if (msg.sender == admin) {
        // Owner can withdraw anything
        require(amount <= treasureBalance, "Not enough treasury available for this action.");
        treasureBalance -= amount;
        return;
        }

        require(amount <= treasureBalance, "Insufficient funds in the treasury");
        require(allowance[msg.sender] > 0, "No Allowance");
        require(!hasWithdrawn[msg.sender], "You have already withdrawn");
        // Removed contradictory hasWithdrawn check that made withdrawal impossible for approved users

        
         treasureBalance -= amount;
         hasWithdrawn[msg.sender] = true;

         emit withdrawal(msg.sender, amount);
    }

    function approveUserWithdrawal(address user, uint amount) external onlyAdmin{
        allowance[user] = amount;
    }

    function resetWithdrawal(address user) external onlyAdmin{
        hasWithdrawn[user] = false;
    }

    function transferOwnership(address newOwner) external onlyAdmin {
        admin = newOwner;
    
    }

    function renounceOwnership() external onlyAdmin {
        admin = address(0);
    }


}