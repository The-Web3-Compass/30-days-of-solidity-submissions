// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
| Concept   | Meaning                                               |
| --------- | ----------------------------------------------------- |
| `event`   | Declares a blockchain log type                        |
| `emit`    | Triggers the event when something happens             |
| `indexed` | Makes that field searchable in event logs             |
| `Logs`    | Stored off-chain but verifiable, cheaper than storage |
*/

/* -------------------------------------------------------------------------- */
/*                          🧠 Knowledge Summary Section                      */
/* -------------------------------------------------------------------------- */
/*
This contract, `EtherPiggyBank`, introduces several new Solidity concepts 
and best practices for managing Ether transfers, event logging, and security.

1️⃣ Events (`event MemberAdded`, `event Deposit`, `event Withdraw`)
   - Events are used for logging important on-chain activities.
   - Once emitted, they are stored in the transaction log and can be indexed.
   - Off-chain apps (like web3.js, ethers.js, or TheGraph) can listen to these 
     events to track contract activity without scanning every block.
   - Example:
        emit MemberAdded(_member);
     Logs the addition of a new member, viewable in blockchain explorers.

2️⃣ Safe Ether Transfer — `call{value: _amount}("")`
   - The modern and recommended way to transfer ETH from a contract to a user.
   - Replaces older (and riskier) methods:
        - `transfer()` (gas limit of 2300, may fail in some cases)
        - `send()` (returns bool but does not revert on failure)
   - Using `call` allows flexible gas forwarding and safer error handling.
   - The call returns a tuple `(bool sent, bytes memory data)`, so we check:
        require(sent, "Failed to send Ether");

3️⃣ Contract Balance Checking — `address(this).balance`
   - `address(this)` refers to the current contract’s address.
   - The `.balance` property returns the total amount of wei stored in the contract.
   - Useful for checking whether enough Ether is available before withdrawing.
   - Example:
        require(address(this).balance >= _amount, "Contract balance too low");

4️⃣ General Best Practices Highlighted
   - ✅ Use `payable` modifiers only where necessary (Ether transfers or deposits).
   - ✅ Protect sensitive functions using `onlyBankManager` and `onlyRegisteredMember` modifiers.
   - ✅ Use `require()` to validate preconditions (security & clarity).
   - ✅ Use events to make on-chain state changes easily traceable.

Together, these techniques make the contract:
   • Safer for handling Ether (prevents accidental locking of funds)
   • Easier to monitor externally (via logs/events)
   • More modular and maintainable (using modifiers and clear mapping structure)
*/

/* -------------------------------------------------------------------------- */
/*                               Contract Code                                */
/* -------------------------------------------------------------------------- */

contract EtherPiggyBank {

    // There should be a bank manager who has certain permissions
    // There should be an array for all registered members and a mapping whether they are registered or not
    // A mapping with their balances

    // - Add a withdrawal function that sends Ether back to users
    // - Add limits, cooldowns, or approval systems

    address public bankManager;
    address[] private members;

    uint256 public singleWithdrawLimit = 1e10; // 0.00000001 ETH = 1e10 wei
    uint256 public withdrawCooldown = 3600;    // 1 hour

    mapping(address => bool) public registeredMembers;
    mapping(address => uint256) public latestWithdrawTime;
    mapping(address => uint256) private balances;

    event MemberAdded(address indexed member); //--> New Knowledge
    event Deposit(address indexed member, uint256 amount);
    event Withdraw(address indexed member, uint256 amount);

    constructor() {
        bankManager = msg.sender;
        registeredMembers[msg.sender] = true;
        members.push(msg.sender);
    }

    modifier onlyBankManager() {
        require(msg.sender == bankManager, "Only bank manager can perform this action");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Member not registered");
        _;
    }

    // Add new members
    function addMember(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address");
        require(!registeredMembers[_member], "Member already registered");
        registeredMembers[_member] = true;
        members.push(_member);
        emit MemberAdded(_member);
    }

    // View all members
    function getMembers() public view returns (address[] memory) {
        return members;
    }

    // Deposit Ether into the contract
    function depositAmountEther() public payable onlyRegisteredMember {
        require(msg.value > 0, "Invalid amount");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Withdraw Ether from the contract (with limits and cooldown)
    function withdrawAmount(uint256 _amount) public onlyRegisteredMember {
        require(block.timestamp - latestWithdrawTime[msg.sender] > withdrawCooldown, "Cooldown active");
        require(_amount <= singleWithdrawLimit, "Amount exceeds single withdraw limit");
        require(_amount > 0, "Invalid amount");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        latestWithdrawTime[msg.sender] = block.timestamp;

        // ✅ Transfer ETH safely to msg.sender --> New Knowledge
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Failed to send Ether");

        emit Withdraw(msg.sender, _amount);
    }

    // Check the balance of a member 
    function getBalance(address _member) public view returns (uint256) {
        require(_member != address(0), "Invalid address");
        return balances[_member];
    }

    // Allow the bank manager to withdraw contract fees (if any) 
    function withdrawManager(uint256 _amount) public onlyBankManager {
        require(address(this).balance >= _amount, "Contract balance too low"); //--> New Knowledge
        (bool sent, ) = payable(bankManager).call{value: _amount}("");
        require(sent, "Transfer failed");
    }

    // View total Ether stored in contract
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
