// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EtherPiggyBank
 * @author shivam
 * @notice A simple contract to simulate an ether piggy bank.
     How it works:
     - Users can deposit and withdraw etherium from the contract.
     - Only the depositer can withdraw.
     - All computations are in wei unit.
 */
contract EtherPiggyBank {
    /// @notice Mapping of user address to total available balance (in wei)
    mapping (address => uint) private balances;

    /// @notice Event emitted when a deposit is made by a user.
    /// @param from Depositor address
    /// @param amount Deposit amount value
    event Deposited(address indexed from, uint indexed amount);

    /// @notice Event emitted when a withdrawal is made by a user.
    /// @param to User address
    /// @param amount Deposit amount value
    event Withdrew(address indexed to, uint indexed amount);

    /// @notice Error thrown when available amount in insufficient for withdrawal.
    /// @param requested Withdrawal amount requested
    /// @param available Available amount
    error InsufficientFunds(uint requested, uint available);

    /// @notice Special function that allows this contract to receive ETH.
    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Fallback function to receive ETH when calldata is not empty
    fallback() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Get balance for caller
    /// @return balance Balance in wei unit
    function getBalance() external view returns (uint) {
        return balances[msg.sender];
    }

    /// @notice Withdraw balance from contract. Balance is transferred to caller's address.
    /// @param amount Withdrawal amount in wei unit
    function withdraw(uint amount) external {
        // check amount
        require(amount > 0, "amount must be greater than 0");
        if (amount > balances[msg.sender]) {
            revert InsufficientFunds(amount, balances[msg.sender]);
        }

        // update state first to prevent reentrancy
        balances[msg.sender] -= amount;

        // transfer amount
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");

        // emit event
        emit Withdrew(msg.sender, amount);
    }
}