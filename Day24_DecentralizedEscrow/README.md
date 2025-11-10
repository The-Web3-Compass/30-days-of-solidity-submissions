# Day 24 – Decentralized Escrow (Advanced Multi-Milestone System)

## Project Overview

Day 24 focuses on creating an advanced decentralized escrow contract that supports multiple milestones, strict deadlines for both deposit and delivery, automated penalty handling, and an arbitration mechanism for disputes. The objective was to design a practical escrow workflow that moves through controlled states from deployment to completion.

## Contract Structure (src Folder)

**DecentralizedEscrow.sol** is the single smart contract that handles the entire logic. The contract defines the buyer, seller, and arbiter, along with milestone data, deadlines, and internal states. Milestones include delivery deadlines, payment amounts, and status tracking. The contract uses events, enums, state variables, and internal checks to ensure a controlled and predictable execution flow.

## Additional Features Implemented

Compared to the base structure, the following enhancements were added:

1. Multi-milestone payment system.
2. Deposit deadline enforcement and contract cancellation if missed.
3. Delivery deadlines for each milestone with automatic penalty if delayed.
4. State-machine control for all major stages of the contract.
5. Arbiter-based dispute resolution for rejected deliveries.
6. Automated ETH handling for deposits and milestone-level payouts.

## Functions Tested in Remix

The following key functions were verified in Remix to demonstrate the intended workflow:

1. Constructor – initializes buyer, seller, arbiter, deadlines, and milestones.
2. deposit() – buyer deposits the required escrow amount and activates the contract.
3. submitDelivery() – seller marks a milestone as delivered.
4. approveDelivery() – buyer approves and releases milestone payment.
5. rejectDelivery() – buyer rejects and raises a dispute.
6. resolveDispute() – arbiter resolves the dispute and assigns payment.
7. autoTriggerDeadline() – checks for missed deadlines and applies penalty logic.

## Outputs

The outputs folder contains screenshots showing the complete flow: contract deployment, initial state, deposit, delivery submission, buyer approval, arbiter action, and Foundry build confirmation.

## Foundry Commands Used

forge build

forge test

## Summary

This task demonstrates a complete escrow lifecycle, including deposits, multi-step delivery, approvals, penalties, and dispute management. The project follows a clear state-driven design with strict deadline rules and secure ETH movement. The folder is fully organized in Foundry format with code, test structure, and deployment outputs.

---

# End of the Project.
