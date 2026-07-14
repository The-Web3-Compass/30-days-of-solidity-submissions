// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FortKnox {

    mapping(address => uint256) public balances;

    // Reentrancy guard variable
    bool private locked;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    /*
     * nonReentrant modifier
     */
    modifier nonReentrant() {
        require(!locked, "Reentrant call detected");
        locked = true;
        _;
        locked = false;
    }

    /*
     * Deposit Ether
     */
    function deposit() external payable {
        require(msg.value > 0, "Send ETH");

        balances[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    /*
     * Secure Withdraw function
     */
    function withdraw() external nonReentrant {

        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");

        // Effects first (update state BEFORE external call)
        balances[msg.sender] = 0;

        // Interaction (external call)
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    /*
     * View balance
     */
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}