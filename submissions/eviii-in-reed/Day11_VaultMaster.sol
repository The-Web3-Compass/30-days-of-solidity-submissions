//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultMaster is Ownable {
    // VaultMaster inherits from Ownable.
    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);

    constructor() Ownable(msg.sender) {}

    // set the deployer as the first owner
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function deposit() public payable {
        require(msg.value > 0, "Cannot accept amount less than 0.");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    function withdraw(address _to, uint256 _amount) public onlyOwner {
        require(_amount <= getBalance(), "Insufficient balance.");

        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer failed.");

        emit WithdrawSuccessful(_to, _amount);
    }
}
