// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultMaster is Ownable {
// contract Child is Parent, meaning Child automatically has 'value' and 'setValue', can now add new functionality

    constructor() Ownable(msg.sender){};

    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);

    function deposit() public payable {
        require(msg.value > 0, "Enter a valid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(address _to, uint256 _amount) public onlyOwner {
            require(_to != address(0), "invalid recipient");
            require(_amount <= getBalance(), "insufficient balance");
            (bool success, ) = payable(_to).call{value: _amount}("");
            require(success, "Transfer failed");
            emit WithdrawSuccessful(_to, _amount);
        }
}