// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract GoldVault {
    mapping(address => uint256) public goldBalance;

    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrant call blocked");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit must be more than zero");
        goldBalance[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function vulnerableWithdraw() external {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Not Enough Balance");

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Withdraw Failed");

        goldBalance[msg.sender] = 0;
        emit Withdrawn(msg.sender, amount);
    }

    function safeWithdraw() external nonReentrant {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Not Enough Balance");

        goldBalance[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Withdraw Failed");

        emit Withdrawn(msg.sender, amount);
    }
}
