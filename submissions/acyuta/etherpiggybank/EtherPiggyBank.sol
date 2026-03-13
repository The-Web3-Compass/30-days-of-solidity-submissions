// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EtherPiggyBank {
    event EthDeposited(uint amountDeposited, address indexed user);
    event EthWithdrawn(uint amountWithdrawn, address indexed user);

    error EtherPiggyBank__NotEnoughEth(uint);
    error EtherPiggyBank__TransactionFailed();
    error EtherPiggyBank__Reentrancy();

    bool private locked;
    mapping(address => uint) private userBalance;

    function depositEth() public payable {
        userBalance[msg.sender] += msg.value;
        emit EthDeposited(msg.value, msg.sender);
    }

    function withdrawEth(uint _amount) public nonReentrancy {
        uint balance = userBalance[msg.sender];
        if (_amount > balance) revert EtherPiggyBank__NotEnoughEth(balance);

        userBalance[msg.sender] -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) revert EtherPiggyBank__TransactionFailed();

        emit EthWithdrawn(_amount, msg.sender);
    }

    function getBalance() public view returns(uint) {
        return userBalance[msg.sender];
    }

    modifier nonReentrancy {
        if(locked) revert EtherPiggyBank__Reentrancy();
        locked = true;
        _;
        locked = false;
    }
}
