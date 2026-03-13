// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// This import is like plugging in a power cord to the Ownable contract
import "./Ownable.sol";
import "./Pausable.sol";

contract VaultMaster is Ownable, Pausable {
    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);

    // This contract has no 'owner' variable, yet it knows what 'onlyOwner' is!

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function deposit() public payable whenNotPaused {
        require(msg.value > 0, "Enter a valid amount");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    function withdraw(address _to, uint256 _amount) public onlyOwner whenNotPaused {
        require(_amount <= getBalance(), "Insufficient balance");

        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer Failed");

        emit WithdrawSuccessful(_to, _amount);
    }
}
