// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

contract AdminOnly {
    address owner;
    address[] public contributers;

    error AdminOnly__InvalidAmount();
    error AdminOnly__UserNotAllowedToWithdraw();
    error AdminOnly__FaildToTransaferFunds();
    error AdminOnly__withdrawAllowenceExeeded();
    error AdminOnly__NotEnoughContribution();

    mapping(address => bool) public isAllowed;
    mapping(address => bool) public isContrubuter;
    mapping(address => uint256) public contribution;
    mapping(address => uint256) public withdraw_allowence;

    constructor() {
        owner = msg.sender;
    }

    modifier m_isAllowed() {
        if (!isAllowed[msg.sender] && msg.sender != owner) {
            revert AdminOnly__UserNotAllowedToWithdraw();
        }
        _;
    }

    modifier m_withdrawAllowence() {
        if (!(withdraw_allowence[msg.sender] > 0)) {
            revert AdminOnly__withdrawAllowenceExeeded();
        }
        _;
    }

    function deposite() public payable {
        if (msg.value < 0) {
            revert AdminOnly__InvalidAmount();
        }
        if (!isContrubuter[msg.sender]) {
            contributers.push(msg.sender);
            isContrubuter[msg.sender] = true;
        }
        contribution[msg.sender] += msg.value;
    }

    function withdraw(uint256 _amount) public m_isAllowed m_withdrawAllowence {
        if(_amount > withdraw_allowence[msg.sender]) {
            revert AdminOnly__withdrawAllowenceExeeded();
        }
        if(_amount > contribution[msg.sender]){
            revert AdminOnly__NotEnoughContribution();
        }
        
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert AdminOnly__FaildToTransaferFunds();
        }
        withdraw_allowence[msg.sender] = 0;
        contribution[msg.sender] = 0;
    }

    function granteAllowence(address _recipint, uint256 _amount) public m_isAllowed {
        if (_amount < 0) {
            revert AdminOnly__InvalidAmount();
        }
        withdraw_allowence[_recipint] += _amount;
    }
}
