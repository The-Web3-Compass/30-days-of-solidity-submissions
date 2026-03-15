// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SafeDepositBox {

    struct Deposit {
        uint256 amount;
        uint256 timestamp;
        string note;
    }

    address public owner;

    // Efficient storage using mapping
    mapping(address => Deposit[]) private userDeposits;

    event DepositStored(address indexed user, uint256 amount, string note);
    event DepositRemoved(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Store deposit information
    function storeDeposit(uint256 _amount, string memory _note) public {
        Deposit memory newDeposit = Deposit({
            amount: _amount,
            timestamp: block.timestamp,
            note: _note
        });

        userDeposits[msg.sender].push(newDeposit);

        emit DepositStored(msg.sender, _amount, _note);
    }

    // View deposits of a user
    function getDeposits(address _user) public view returns (Deposit[] memory) {
        return userDeposits[_user];
    }

    // Remove last deposit entry
    function removeLastDeposit() public {

        require(userDeposits[msg.sender].length > 0, "No deposits found");

        uint256 lastIndex = userDeposits[msg.sender].length - 1;
        uint256 amount = userDeposits[msg.sender][lastIndex].amount;

        userDeposits[msg.sender].pop();

        emit DepositRemoved(msg.sender, amount);
    }

    // Get number of deposits for a user
    function getDepositCount(address _user) public view returns (uint256) {
        return userDeposits[_user].length;
    }
}