// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EtherPiggyBank {
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "Must send some Ether");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external {
        uint256 userBalance = balances[msg.sender];
        require(userBalance >= _amount, "Insufficient balance");

        unchecked {
            balances[msg.sender] = userBalance - _amount;
        }

        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Ether transfer failed");

        emit Withdraw(msg.sender, _amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
