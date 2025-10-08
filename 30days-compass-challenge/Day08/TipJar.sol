// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    address public owner;
    uint256 public totalTips;

    struct Tip {
        address sender;
        uint256 amount; // in wei
        string currency; // e.g. "USD", "EUR", "ETH"
        uint256 convertedAmount; // converted value in smallest unit of currency
        string message;
    }

    Tip[] public tips;
    mapping(address => uint256) public userTips;

    event Tipped(address indexed from, uint256 amount, string currency, uint256 convertedAmount, string message);
    event Withdrawn(address indexed by, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    // Send a tip with optional currency simulation (ETH, USD, EUR)
    function sendTip(string memory currency, uint256 convertedAmount, string memory message) public payable {
        require(msg.value > 0, "Must send some Ether to tip");

        tips.push(Tip({
            sender: msg.sender,
            amount: msg.value,
            currency: currency,
            convertedAmount: convertedAmount,
            message: message
        }));

        userTips[msg.sender] += msg.value;
        totalTips += msg.value;

        emit Tipped(msg.sender, msg.value, currency, convertedAmount, message);
    }

    // Owner can withdraw accumulated tips
    function withdrawTips() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds to withdraw");

        payable(owner).transfer(amount);
        emit Withdrawn(owner, amount);
    }

    // Get total number of tips
    function getTotalTips() public view returns (uint256) {
        return tips.length;
    }

    // Get all tips sent by a user
    function getUserTips(address _user) public view returns (uint256) {
        return userTips[_user];
    }
}
