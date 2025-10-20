//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract GoldVault{

    uint256 private _status;
    uint256 private _NOT_ENTERED = 1;
    uint256 private _ENTERED = 2;

    mapping(address => uint256) public goldBalance;

    constructor(){
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant(){
        require(_status != _ENTERED, "Entrance restricted");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    function deposit() external payable{
        require(msg.value > 0, "Deposit value has to be more than 0");
        goldBalance[msg.sender] += msg.value;
    }

    function vulnerableWithdraw() external{
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        (bool success,) = msg.sender.call{value:amount}("");
        require(success, "Ether transfer failed");
        goldBalance[msg.sender] = 0;
    }

    function safeWithdraw() external nonReentrant{
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        goldBalance[msg.sender] = 0;
        (bool success,) = msg.sender.call{value:amount}("");
        require(success, "Ether transfer failed");
    }
    
}
