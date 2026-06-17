// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract GoldVault {
    mapping(address => uint256) public goldBalance;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        if (_status == _ENTERED) revert ReentrantCall();
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    error ReentrantCall();
    error ZeroDeposit();
    error InsufficientBalance();
    error WithdrawFailed();

    function deposit() external payable {
        if (msg.value == 0) revert ZeroDeposit();
        goldBalance[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function vulnerableWithdraw() external {
        uint256 amount = goldBalance[msg.sender];
        if (amount == 0) revert InsufficientBalance();

        (bool sent, ) = msg.sender.call{value: amount}("");
        if (!sent) revert WithdrawFailed();

        goldBalance[msg.sender] = 0;
        emit Withdrawn(msg.sender, amount);
    }

    function safeWithdraw() external nonReentrant {
        uint256 amount = goldBalance[msg.sender];
        if (amount == 0) revert InsufficientBalance();

        goldBalance[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: amount}("");
        if (!sent) revert WithdrawFailed();

        emit Withdrawn(msg.sender, amount);
    }
}