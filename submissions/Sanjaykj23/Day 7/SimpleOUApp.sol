// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SimpleIOU {
    address public owner;
    mapping(address => bool) public isFriend;
    mapping(address => uint256) public balances; // Actual ETH held by contract
    mapping(address => mapping(address => uint256)) public debt; // [ower][creditor]

    event Deposit(address indexed user, uint256 amount);
    event BillPaid(address indexed payer, uint256 totalAmount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyFriend() {
        require(isFriend[msg.sender], "Not a friend");
        _;
    }

    function addFriend(address _adr) external {
        // In a real app, maybe anyone can add friends, or just owner
        require(msg.sender == owner, "Only owner");
        isFriend[_adr] = true;
    }

    // INDUSTRY FIX: Uses 'payable' and 'msg.value' to actually take the ETH
    function deposit() external payable onlyFriend {
        require(msg.value > 0, "Send ETH to deposit");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // INDUSTRY FIX: Handles splitting logic and uses internal balances
    function payBill(uint256 _totalAmt, address[] calldata _involvedFriends) external onlyFriend {
        require(balances[msg.sender] >= _totalAmt, "Insufficient balance");
        
        balances[msg.sender] -= _totalAmt;
        uint256 share = _totalAmt / (_involvedFriends.length + 1); // +1 includes the payer

        for (uint256 i = 0; i < _involvedFriends.length; i++) {
            address friend = _involvedFriends[i];
            if (friend == msg.sender) continue;
            debt[friend][msg.sender] += share;
        }
        
        emit BillPaid(msg.sender, _totalAmt);
        // Note: In a real app, you'd then call a shop address here if needed
    }

    // INDUSTRY FIX: "Pull" pattern. Creditor withdraws what they are owed.
    function settleDebt(address _creditor) external onlyFriend {
        uint256 amount = debt[msg.sender][_creditor];
        require(amount > 0, "No debt to settle");
        require(balances[msg.sender] >= amount, "Deposit more ETH first");

        debt[msg.sender][_creditor] = 0;
        balances[_creditor] += amount;
        balances[msg.sender] -= amount;
    }

    // Let users take their money back to their real wallet
    function withdraw(uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "Low balance");
        balances[msg.sender] -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
    }
}