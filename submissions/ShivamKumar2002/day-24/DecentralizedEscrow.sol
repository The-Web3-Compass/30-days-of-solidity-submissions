// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Decentralized Escrow
 * @author shivam
 * @notice A secure system for holding funds until conditions are met, involving a Buyer, Seller, and Arbiter.
 * @dev This contract facilitates secure conditional payments and dispute resolution without external libraries.
 */
contract DecentralizedEscrow {
    /// @notice The address of the buyer in the escrow.
    address payable public buyer;
    /// @notice The address of the seller in the escrow.
    address payable public seller;
    /// @notice The address of the trusted arbiter for dispute resolution.
    address public arbiter;

    /// @notice The possible states of the escrow process.
    enum State {
        Created,    // Initial state, waiting for buyer to deposit funds.
        Funded,     // Funds have been deposited by the buyer.
        Dispute,    // A dispute has been initiated by either party.
        Closed,     // Escrow is concluded, funds sent to seller (or withdrawn).
        Refunded    // Escrow is concluded, funds refunded to buyer (or withdrawn).
    }
    /// @notice The current state of the escrow.
    State public currentState;

    /// @notice Emitted when the buyer successfully deposits funds into the escrow.
    /// @param buyer The address of the buyer who deposited funds.
    /// @param amount The amount of ether deposited (in wei).
    event FundsDeposited(address indexed buyer, uint256 amount);

    /// @notice Emitted when the buyer confirms receipt of goods/services.
    /// @param buyer The address of the buyer who confirmed receipt.
    event ReceiptConfirmed(address indexed buyer);

    /// @notice Emitted when either the buyer or seller initiates a dispute.
    /// @param party The address of the party who initiated the dispute.
    event DisputeInitiated(address indexed party);

    /// @notice Emitted when the arbiter records a decision in case of a dispute.
    /// @param arbiter The address of the arbiter who made the decision.
    /// @param winner The address of the party who won the dispute (buyer or seller).
    event DecisionRecorded(address indexed arbiter, address indexed winner);

    /// @notice Emitted when funds are successfully withdrawn by the designated recipient.
    /// @param recipient The address of the recipient (buyer or seller).
    /// @param amount The amount of ether withdrawn (in wei).
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    /**
     * @notice Initializes a new escrow contract.
     * @param _buyer The address of the buyer.
     * @param _seller The address of the seller.
     * @param _arbiter The address of the trusted arbiter.
     */
    constructor(address payable _buyer, address payable _seller, address _arbiter) {
        require(_buyer != address(0), "Buyer address cannot be zero");
        require(_seller != address(0), "Seller address cannot be zero");
        require(_arbiter != address(0), "Arbiter address cannot be zero");
        buyer = _buyer;
        seller = _seller;
        arbiter = _arbiter;
        currentState = State.Created;
    }

    /**
     * @notice Allows the buyer to deposit the agreed-upon amount of ether into escrow.
     * @dev Can only be called when the escrow is in the `Created` state.
     */
    function deposit() external payable {
        require(currentState == State.Created, "Escrow must be in Created state to deposit");
        require(msg.sender == buyer, "Only buyer can deposit");
        require(msg.value > 0, "Amount must be greater than zero");
        currentState = State.Funded;
        emit FundsDeposited(buyer, msg.value);
    }

    /**
     * @notice Allows the buyer to confirm receipt of the goods or services.
     * @dev Can only be called by the buyer when the escrow is in the `Funded` state. Transfers funds to the seller.
     */
    function confirmReceipt() external {
        require(msg.sender == buyer, "Only the buyer can confirm receipt");
        require(currentState == State.Funded, "Escrow must be in Funded state to confirm receipt");

        currentState = State.Closed;
        emit ReceiptConfirmed(buyer);

        uint256 balance = address(this).balance;

        // try to send funds directly to the seller
        (bool success, ) = seller.call{value: balance}("");
        if (success) {
            emit FundsWithdrawn(seller, balance);
        } else {
            // If transfer fails, funds remain in contract for seller to withdraw
            // The state is already Closed, allowing seller to call withdraw()
        }
    }

    /**
     * @notice Allows either the buyer or the seller to initiate a dispute.
     * @dev Can only be called by the buyer or seller when the escrow is in the `Funded` state. Changes the state to `Dispute`.
     */
    function initiateDispute() external {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can initiate a dispute");
        require(currentState == State.Funded, "Escrow must be in Funded state to initiate dispute");

        currentState = State.Dispute;
        emit DisputeInitiated(msg.sender);
    }

    /**
     * @notice Allows the arbiter to record a decision in case of a dispute.
     * @dev Can only be called by the arbiter when the escrow is in the `Dispute` state. Transfers funds to the designated winner (buyer or seller).
     * @param _winner The address of the party who won the dispute (buyer or seller).
     */
    function recordDecision(address payable _winner) external {
        require(msg.sender == arbiter, "Only the arbiter can record a decision");
        require(currentState == State.Dispute, "Escrow must be in Dispute state to record decision");
        require(_winner == buyer || _winner == seller, "Winner must be either the buyer or the seller");

        uint256 balance = address(this).balance;

        if (_winner == seller) {
            currentState = State.Closed;
            // Attempt to send funds directly to the seller
            (bool success, ) = seller.call{value: balance}("");
            // If transfer fails, funds remain in contract for seller to withdraw
            // The state is already Closed, allowing seller to call withdraw()
            if (success) {
                emit FundsWithdrawn(seller, balance);
            }
        } else { // _winner == buyer
            currentState = State.Refunded;
            // Attempt to send funds directly to the buyer
            (bool success, ) = buyer.call{value: balance}("");
            // If transfer fails, funds remain in contract for buyer to withdraw
            // The state is already Refunded, allowing buyer to call withdraw()
            if (success) {
                emit FundsWithdrawn(buyer, balance);
            }
        }

        emit DecisionRecorded(arbiter, _winner);
    }

    /**
     * @notice Allows the designated winner to withdraw funds if the direct transfer failed.
     * @dev Can only be called by the buyer (if refunded) or seller (if closed) when the escrow is in the `Closed` or `Refunded` state.
     */
     function withdraw() external {
        require(currentState == State.Closed || currentState == State.Refunded, "Escrow must be in Closed or Refunded state to withdraw");

        address payable intendedRecipient;
        if (currentState == State.Closed) {
            intendedRecipient = seller;
        } else { // currentState == State.Refunded
            intendedRecipient = buyer;
        }

        require(msg.sender == intendedRecipient, "Only the designated winner can withdraw");

        // use actual balance instead of amount
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success, ) = intendedRecipient.call{value: balance}("");
        require(success, "Withdrawal failed");

        // Note: We don't change the state here as it reflects the final outcome.
        // The balance check prevents multiple withdrawals.
        emit FundsWithdrawn(intendedRecipient, balance);
    }
}