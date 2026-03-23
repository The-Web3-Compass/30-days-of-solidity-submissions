    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error UnAuthorized(address caller);
error UserWithdrawFunction(address owner);
error NoAllowance(address caller);
error WithdrawnUser(address caller);
error AlreadyNotWithdrawn(address user);
error InsufficientAllowance(uint256 amount, uint256 balance);
error InsufficientChestBalance(uint256 amount, uint256 balance);
error InvalidAddress(address user);
error WithdrawFailed();
error AlreadyApproved(address user);
error ZeroAmountNotAllowed();

contract AdminOnly {
    address private s_owner;
    uint256 public totalSupply;

    mapping(address => uint256) public allowance;
    mapping(address => bool) public isApproved;
    mapping(address => bool) public isWithdrawn;

    event Deposited(address indexed user, uint256 amount);
    event WithdrawalApproved(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount, uint256 timestamp);
    event WithdrawalReset(address indexed user);
    event OwnershipTransferred(address oldOwner, address newOwner);

    modifier onlyOwner() {
        if (msg.sender != s_owner) revert UnAuthorized(msg.sender);
        _;
    }

    modifier onlyApproved(address user) {
        if (!isApproved[user]) revert NoAllowance(user);
        _;
    }

    modifier checkZeroAmount(uint256 amount) {
        if (amount == 0) revert ZeroAmountNotAllowed();
        _;
    }

    modifier checkZeroAddress(address caller) {
        if (caller == address(0)) revert InvalidAddress(caller);
        _;
    }

    receive() external payable {
        deposit();
    }

    constructor() {
        s_owner = msg.sender;
    }

    function deposit() public payable checkZeroAmount(msg.value) onlyOwner {
        address depositor = msg.sender;
        uint256 depositAmount = msg.value;
        totalSupply += depositAmount;
        emit Deposited(depositor, depositAmount);
    }

    function approveWithdrawal(address _user, uint256 _amount)
        external
        checkZeroAddress(_user)
        checkZeroAmount(_amount)
        onlyOwner
    {
        if (isApproved[_user]) revert AlreadyApproved(_user);
        if (_amount > totalSupply) revert InsufficientChestBalance(_amount, totalSupply);
        isApproved[_user] = true;
        allowance[_user] = _amount;
        emit WithdrawalApproved(_user, _amount);
    }

    function resetWithdrawal(address _user) external checkZeroAddress(_user) onlyOwner {
        if (!isWithdrawn[_user]) revert AlreadyNotWithdrawn(_user);
        // allowance is expected to be zero after withdraw; withdrawn status is the relevant reset gate
        isWithdrawn[_user] = false;
        emit WithdrawalReset(_user);
    }

    function withdraw(uint256 _amount) external checkZeroAmount(_amount) onlyApproved(msg.sender) {
        address user = msg.sender;
        if (user == s_owner) revert UserWithdrawFunction(s_owner);
        if (isWithdrawn[user]) revert WithdrawnUser(user);
        if (allowance[user] == 0) revert NoAllowance(user);
        if (_amount > allowance[user]) revert InsufficientAllowance(_amount, allowance[user]);
        if (_amount > totalSupply) revert InsufficientChestBalance(_amount, totalSupply);
        isWithdrawn[user] = true;
        isApproved[user] = false;
        allowance[user] = 0;
        _withdraw(user, _amount);
    }

    function ownerWithdraw(uint256 _amount) external checkZeroAmount(_amount) onlyOwner {
        if (_amount > totalSupply) revert InsufficientChestBalance(_amount, totalSupply);
        _withdraw(s_owner, _amount);
    }

    function transferOwnership(address _newOwner) external checkZeroAddress(_newOwner) onlyOwner {
        address oldOwner = s_owner;
        address newOwner = _newOwner;
        s_owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _withdraw(address _user, uint256 _amount) internal {
        totalSupply -= _amount;
        emit Withdrawal(_user, _amount, block.timestamp);
        (bool success,) = payable(_user).call{value: _amount}("");
        if (success == false) revert WithdrawFailed();
    }
}
