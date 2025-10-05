// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TreasureChest {
    address public owner;
    uint256 public treasureBalance;

    mapping(address => bool) public approvedUsers;
    mapping(address => bool) public hasWithdrawn;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event TreasureAdded(uint256 amount);
    event UserApproved(address indexed user);
    event Withdrawal(address indexed user, uint256 amount);
    event WithdrawalReset(address indexed user);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner!");
        _;
    }

    function addTreasure() external payable onlyOwner {
        require(msg.value > 0, "Must add some treasure!");
        treasureBalance += msg.value;
        emit TreasureAdded(msg.value);
    }

    function approveUser(address _user) external onlyOwner {
        approvedUsers[_user] = true;
        hasWithdrawn[_user] = false;
        emit UserApproved(_user);
    }

    function withdraw(uint256 _amount) external {
        require(approvedUsers[msg.sender], "Not approved!");
        require(!hasWithdrawn[msg.sender], "Already withdrawn!");
        require(_amount <= treasureBalance, "Not enough treasure!");

        hasWithdrawn[msg.sender] = true;
        treasureBalance -= _amount;

        payable(msg.sender).transfer(_amount);
        emit Withdrawal(msg.sender, _amount);
    }

    function resetWithdrawal(address _user) external onlyOwner {
        hasWithdrawn[_user] = false;
        emit WithdrawalReset(_user);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address!");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
