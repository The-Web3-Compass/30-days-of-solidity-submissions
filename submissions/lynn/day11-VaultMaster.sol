//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "./day11-Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultMaster is Ownable {
    // Set deployer as owner using OpenZeppelin's constructor
    constructor() Ownable(msg.sender) {}

    event DepositSuccess(address indexed depositor, uint256 amount);
    event WithdrawSuccess(address indexed withdrawer, uint256 amount);

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function deposit() public payable {
        require(msg.value > 0, "The amount should be greater than 0");
        emit DepositSuccess(msg.sender, msg.value);
    }

    function withdraw(address _to, uint256 _amount) public onlyOwner {
        require(address(0) != _to, "Invalid address");
        require(_amount <= getBalance(), "Insufficient balance");

        (bool success, ) = payable(_to).call{value : _amount}("");
        require(success, "Withdraw failed");

        emit WithdrawSuccess(_to, _amount);
    }

    
}