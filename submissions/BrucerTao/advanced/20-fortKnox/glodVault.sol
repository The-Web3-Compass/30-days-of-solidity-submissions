// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract GoldVault {
    mapping(address => uint256) public goldBalance;

    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "reentrant call blocked");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    //存储eth
    function deposit() external payable {
        require(msg.value > 0, "deposit must be more than 0");
        goldBalance[msg.sender] += msg.value;

    }

    //脆弱的提取eth
    function vulnerableWithdraw() external {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "nothing to withdraw");

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "eth transfer failed");

        goldBalance[msg.sender] = 0;
    }

    //安全的提取eth
    function safeWithdraw() external nonReentrant {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "nothing to withdraw");

        goldBalance[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "eth transfer failed");

    }

}