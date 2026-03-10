// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SendSomeTokens {
    event TokensSent();
    event TokensReceived();

    error SendSomeTokens__NotAuthorized();
    error SendSomeTokens__NotEnoughTokens();
    error SendSomeTokens__TransactionFailed();
    
    address private immutable i_owner;
    uint private balance;

    constructor() {
        i_owner = msg.sender;
    }

    function sendTokens(address _address, uint _amount) public {
        if (_amount > balance) revert SendSomeTokens__NotEnoughTokens();

        (bool success, ) = payable(_address).call{value: _amount}("");
        if (!success) {
            revert SendSomeTokens__TransactionFailed();
        }

        balance -= _amount;
        emit TokensSent();
    }

    function getTokens() public payable ownerOnly {
        balance += msg.value;
        emit TokensReceived();
    }

    function getBalance() public view returns(uint){
        return balance;
    }

    modifier ownerOnly() {
        if (msg.sender != i_owner) revert SendSomeTokens__NotAuthorized();
        _;
    }
}
