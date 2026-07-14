// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract EtherPiggyBank {
    address public whosInCharge;
    address[] public users;

    mapping(address user => bool isAllowed) public isUser;
    mapping(address user => uint256 totalAmount) public balance;

    constructor() {
        whosInCharge = msg.sender;
        users.push(msg.sender);
    }

    modifier onlyInCharge() {
        require(msg.sender == whosInCharge, "You're not in charge!");
        _;
    }

    modifier onlyAllowedUsers() {
        require(isUser[msg.sender], "You're not allowed here!");
        _;
    }

    function addUser(address newUser) public onlyInCharge {
        require(newUser != address(0), "Invalid address!");
        require(newUser != whosInCharge, "You're already in!");
        require(!isUser[newUser], "User's already in!");

        isUser[newUser] = true;
        users.push(newUser);
    }

    function getListOfUsers() public view returns (address[] memory) {
        return users;
    }

    function deposit() public payable onlyAllowedUsers {
        require(msg.value > 0, "You can't deposit 0!");
        balance[msg.sender] += msg.value;
    }

    function withdraw(uint256 amountWithdrawn) public onlyAllowedUsers {
        require(amountWithdrawn > 0, "You can't withdraw 0!");
        require(
            amountWithdrawn <= balance[msg.sender],
            "You don't have enough money"
        );
        balance[msg.sender] -= amountWithdrawn;
    }
}
