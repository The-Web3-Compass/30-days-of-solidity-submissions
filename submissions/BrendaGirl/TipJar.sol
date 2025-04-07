// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    
    address public owner;

    // Event for logging tips
    event TipReceived(address indexed from, uint256 amount, string message);
    event Withdrawal(address indexed to, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    // Modifier to restrict function to the owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    // Function to send a tip with an optional message
    function sendTip(string memory _message) public payable {
        require(msg.value > 0, "Tip amount must be greater than zero");
        emit TipReceived(msg.sender, msg.value, _message);
    }

    // Function for the owner to withdraw all collected tips
    function withdrawTips() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No tips to withdraw");

        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Withdrawal failed");

        emit Withdrawal(owner, balance);
    }

    // Check how much ETH is in the tip jar
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
