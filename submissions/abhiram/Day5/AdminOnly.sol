//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title AdminOnly
 * @dev A contract that allows only the owner to manage a treasure chest and approve withdrawals for beneficiaries.
 * The owner can add treasure, approve withdrawals, and reset withdrawal statuses.
 * Beneficiaries can withdraw their approved amounts only once.
 */
contract AdminOnly {
	address public owner;

	mapping(address => uint256) private allowances; // Approved withdrawal amounts for beneficiaries
	mapping(address => bool) private hasWithdrawn; // Tracks if a beneficiary has withdrawn their treasure

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event TreasureAdded(address indexed from, uint256 amount);
	event WithdrawalApproved(address indexed beneficiary, uint256 amount);
	event TreasureWithdrawn(address indexed beneficiary, uint256 amount);
	event WithdrawalReset(address indexed beneficiary);

    // Function modifier to ensure that only the owner can call a function
	modifier onlyOwner() {
		require(msg.sender == owner, "Caller is not the owner");
		_;
	}

	constructor() {
		owner = msg.sender;
		emit OwnershipTransferred(address(0), msg.sender);
	}

    // Function to add treasure to the chest, only callable by the owner
	function addTreasure() external payable onlyOwner {
		require(msg.value > 0, "No treasure sent");
		emit TreasureAdded(msg.sender, msg.value);
	}

    // Function to approve a withdrawal for a beneficiary address, only callable by the owner
	function approveWithdrawal(address _beneficiary, uint256 _amount) external onlyOwner {
		require(_beneficiary != address(0), "Invalid beneficiary");
		allowances[_beneficiary] = _amount;
		hasWithdrawn[_beneficiary] = false;
		emit WithdrawalApproved(_beneficiary, _amount);
	}

    // Function to check the allowance of a beneficiary
	function allowanceOf(address _beneficiary) external view returns (uint256) {
		return allowances[_beneficiary];
	}

    // Function to check if a beneficiary has withdrawn their treasure
	function hasWithdrawnTreasure(address _beneficiary) external view returns (bool) {
		return hasWithdrawn[_beneficiary];
	}

    // Function for beneficiaries to withdraw their approved amount
	function withdraw() external {
		uint256 amount = allowances[msg.sender];
		require(amount > 0, "No allowance");
		require(!hasWithdrawn[msg.sender], "Already withdrawn");
		require(amount <= address(this).balance, "Insufficient treasure");

		hasWithdrawn[msg.sender] = true;
		allowances[msg.sender] = 0;

		(bool sent, ) = msg.sender.call{value: amount}("");
		require(sent, "Withdrawal failed");

		emit TreasureWithdrawn(msg.sender, amount);
	}

    // Function for the owner to withdraw any amount to their own address
	function ownerSelfWithdraw(uint256 _amount) external onlyOwner {
		require(_amount > 0, "Amount must be greater than zero");
		require(_amount <= address(this).balance, "Insufficient treasure");

		(bool sent, ) = payable(owner).call{value: _amount}("");
		require(sent, "Withdrawal failed");

		emit TreasureWithdrawn(owner, _amount);
	}

    // Function for the owner to withdraw any amount to a specified recipient
    function ownerRecipientWithdraw(uint256 _amount, address payable _recipient) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient");
        require(_amount > 0, "Amount must be greater than zero");
        require(_amount <= address(this).balance, "Insufficient treasure");

        (bool sent, ) = _recipient.call{value: _amount}("");
        require(sent, "Withdrawal failed");

        emit TreasureWithdrawn(_recipient, _amount);
    }

    // Function for the owner to reset the withdrawal status of a beneficiary
	function resetWithdrawalStatus(address _beneficiary) external onlyOwner {
		hasWithdrawn[_beneficiary] = false;
		emit WithdrawalReset(_beneficiary);
	}

    // Function to transfer ownership to a new owner
	function transferOwnership(address _newOwner) external onlyOwner {
		require(_newOwner != address(0), "New owner is the zero address");
		address previousOwner = owner;
		owner = _newOwner;
		emit OwnershipTransferred(previousOwner, _newOwner);
	}

    // Function to check the current balance of the treasure chest
	function chestBalance() external view returns (uint256) {
		return address(this).balance;
	}

    // Fallback function to receive treasure
	receive() external payable {
		emit TreasureAdded(msg.sender, msg.value);
	}
}

