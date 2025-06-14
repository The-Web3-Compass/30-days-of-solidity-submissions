// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TreasureChest {
    address public owner;
    uint256 public treasure;
    
    mapping(address => uint256) public allowances;
    mapping(address => bool) public hasWithdrawn;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TreasureAdded(uint256 amount);
    event AllowanceSet(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event WithdrawalReset(address indexed user);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addTreasure() external payable onlyOwner {
        require(msg.value > 0, "Must send treasure");
        treasure += msg.value;
        emit TreasureAdded(msg.value);
    }

    function setAllowance(address _user, uint256 _amount) external onlyOwner {
        allowances[_user] = _amount;
        emit AllowanceSet(_user, _amount);
    }

    function withdraw() external {
        uint256 amount = 0;
        
        if (msg.sender == owner) {
            amount = treasure;
        } else {
            require(allowances[msg.sender] > 0, "No allowance set");
            require(!hasWithdrawn[msg.sender], "Already withdrawn");
            amount = allowances[msg.sender];
            hasWithdrawn[msg.sender] = true;
        }
        
        require(treasure >= amount, "Insufficient treasure");
        treasure -= amount;
        
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount);
    }

    function resetWithdrawal(address _user) external onlyOwner {
        hasWithdrawn[_user] = false;
        emit WithdrawalReset(_user);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    // Fallback function to prevent accidental ETH sends
    receive() external payable {
        revert("Use addTreasure to deposit");
    }
}