//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

// Reentrancy attack:
// A reentrancy attack is a class of security vulnerability in smart contracts where an external, untrusted contract is allowed to re-enter the caller contract during the execution of a state-changing operation, before the original state update is finalized, thereby enabling malicious manipulation of shared state.

// This contract would simulate an actual hack and then patch the vulnerability.

// Work Flow:
// Users can deposit ETH into the vault. Think of it as storing digital gold.
// Later, they can withdraw that gold anytime.
// We’ll first implement a basic withdrawal function — no guardrails, no protection.
// Then, we’ll walk you through how an attacker can abuse this vulnerability to drain the contract.
// Once you’ve seen it break, we’ll show you how to lock it down using a simple but powerful "nonReentrant" modifier — a custom-built defense mechanism that acts like a “one-at-a-time” security lock.

contract GoldVault{
    mapping(address=>uint256) public goldBalance; // It tracks how much ETH each user has stored in the vault.

    // Reentrancy lock setup
    uint256 private _status; // It is a private variable that tells us whether a sensitive function (like "safeWithdraw") is currently being executed.
    uint256 private constant _NOT_ENTERED=1;// When the value is 1, the function is not being used right now and it is safe to enter.
    uint256 private constant _ENTERED=2;// When the value is 2, someone is already inside this function.

    constructor(){
        _status=_NOT_ENTERED;
    }

    // Custom nonReentrant modifier--locks the function during execution
    // This modifier ensures that only one call at a time can be inside a protected function.
    // Even if an external contract tries to call back into the vault, they hit the lock and get blocked instantly.
    modifier nonReentrant(){
        require(_status!=_ENTERED,"Reentrant call blocked");
        _status=_ENTERED;
        _;// actual function body
        _status=_NOT_ENTERED;
    }

    function deposit() external payable{
        require(msg.value>0,"Deposit must be more than 0");
        goldBalance[msg.sender]+=msg.value;
    }

    // It is vulnerable withdraw function. It sends ETH before updating the user's balance and leaves the door wide open for during withdrawal.
    function vulnerableWithdraw() external{
        uint256 amount=goldBalance[msg.sender];
        require(amount>0,"Nothing to withdraw");

        // Send the ETH back to msg.sender.
        // But if msg.sender is a smart contract, its "receive()" function gets triggered as soon as it receives ETH. 
            // And inside that "receive()", it calls "vulunerableWithdraw()" again.
        (bool sent,)=msg.sender.call{value:amount}("");
        require(sent, "ETH transfer failed");
        goldBalance[msg.sender]=0;
    }
    
    // Reentrancy attack:
    // - External call made before state is updated;
    // - Attacker re-enters while the vault is still in the middle of processing;
    // - ETH gets drained multiple times from a single balance.

    // **Reentrancy does not change goldBalance[user] during the attack loop — it remains unchanged until the very end — but it repeatedly triggers ETH transfers from address(this).balance to the attacker before the balance is zeroed, allowing the attacker to drain the contract’s real ETH reserves using a single, unreduced goldBalance value.
    // "goldBalance[user]" is just a ledger, "address(this)" is the actual account for ETH transfer
    
    // This function uses a handmade "nonReentrant" modifier to block any recursive attack attempts and safely lock the vault during withdrawal.
    // "nonReentrant" modifier:
        // The moment someone enters the function, it locks it down;
        // If the same address tries to call it again--even through a fallback, it gets blocked immediately.
    // This function follows "Checks-Effects-Interactions" pattern:
    // 1. Check conditions
        // require(amount>0,"Nothing to withdraw");
    // 2. Effect changes to state
        // goldBalance[msg.sender]=0;
    // 3. Interact with external contracts
        // msg.sender.call{value:amount}("");
    function safeWithdraw() external nonReentrant{
        uint256 amount=goldBalance[msg.sender];
        require(amount>0,"Nothing to withdraw");

        // This line happens before we send any ETH. That means the moment the withdrawl begins, we've already cleared out the user's balance.
        // Even if the attacker tries to reenter the function, they'll see their balance is 0.
        goldBalance[msg.sender]=0;
        (bool sent,)=msg.sender.call{value:amount}("");
        require(sent,"ETH transfer failed");

    }
}