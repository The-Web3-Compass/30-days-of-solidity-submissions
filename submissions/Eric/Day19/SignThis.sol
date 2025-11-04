//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title SingThis
 * @author Eric (https://github.com/0xxEric)
 * @notice SignatureGate.sol
 * @custom:project 30-days-of-solidity-submissions: Day19
 */

/*
  SignatureGate.sol

  Purpose:
  - Off-chain signed invitations + on-chain signature verification using per-user nonces.
  - Organizer (owner) signs messages off-chain for invited guests:
      signedMessage = sign( keccak256(abi.encodePacked(guest, eventId, nonce)) )
  - Guest submits (eventId, nonce, signature) on-chain to prove invitation.
  - Contract verifies signature via ECDSA.recover and checks nonce == nonces[guest].
  - After successful entry, the guest's nonce is incremented, preventing replay.
  - Organizer can revoke/update an individual guest by incrementing that guest's nonce on-chain.
*/

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SignatureGate {
    using ECDSA for bytes32;

    // organizer (address whose private key created valid signatures)
    address public organizer;

    // per-user nonce: nonces[guest] is the expected nonce for that guest
    mapping(address => uint256) public nonces;

    // record whether a guest has entered a specific event: entered[eventIdHash][guest] = true
    mapping(bytes32 => mapping(address => bool)) public entered;

    // owner/administrator who can manage organizer and nonces
    address public owner;

    // events
    event OrganizerChanged(address indexed oldOrganizer, address indexed newOrganizer);
    event GuestRevoked(address indexed guest, uint256 newNonce);
    event EventEntered(address indexed guest, uint256 indexed eventId, uint256 usedNonce);

    // modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "SignatureGate: only owner");
        _;
    }

    /**
     * @notice Construct the contract with initial owner and organizer
     * @param _organizer address whose signatures are considered valid
     */
    constructor(address _organizer) {
        require(_organizer != address(0), "SignatureGate: organizer zero");
        owner = msg.sender;
        organizer = _organizer;
    }

    /* ===================== Public / Guest Functions ===================== */

    /**
     * @notice Guest calls this to enter an event by presenting organizer's signature.
     * @param eventId numeric id of the event
     * @param nonce per-user nonce included in the signed message
     * @param signature organizer's signature over (guest, eventId, nonce)
     *
     * Message that should have been signed off-chain:
     *   keccak256(abi.encodePacked(guestAddress, eventId, nonce))
     * and then signed using Ethereum's personal_sign (i.e. the signed hash should be
     * recovered using toEthSignedMessageHash).
     */
    function enterEvent(uint256 eventId, uint256 nonce, bytes calldata signature) external {
        // 1) Check nonce matches expected per-user nonce
        require(nonce == nonces[msg.sender], "SignatureGate: invalid nonce");

        // 2) Reconstruct message hash that organizer signed
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, eventId, nonce));
        bytes32 ethSigned = messageHash.toEthSignedMessageHash();

        // 3) Recover signer and verify it's the organizer
        address recovered = ethSigned.recover(signature);
        require(recovered == organizer, "SignatureGate: invalid signature");

        // 4) Prevent double entry for same (eventId, guest)
        bytes32 eventHash = keccak256(abi.encodePacked(eventId));
        require(!entered[eventHash][msg.sender], "SignatureGate: already entered");

        // 5) Mark entered and increment nonce to prevent replay
        entered[eventHash][msg.sender] = true;
        nonces[msg.sender] += 1;

        emit EventEntered(msg.sender, eventId, nonce);
    }

    /* ===================== Owner / Organizer Management ===================== */

    /**
     * @notice Change the organizer address (who's allowed to sign invites).
     * @param newOrganizer new organizer address
     */
    function setOrganizer(address newOrganizer) external onlyOwner {
        require(newOrganizer != address(0), "SignatureGate: zero organizer");
        address old = organizer;
        organizer = newOrganizer;
        emit OrganizerChanged(old, newOrganizer);
    }

    /**
     * @notice Revoke or invalidate previous signatures for a single guest by bumping their nonce.
     * @dev This is how organizer/owner can make previously issued signatures for `guest` invalid.
     *      Callers with owner privilege can increment the user's nonce to a new value.
     * @param guest address of the guest to revoke/update
     */
    function revokeGuest(address guest) external onlyOwner {
        nonces[guest] += 1;
        emit GuestRevoked(guest, nonces[guest]);
    }

    /**
     * @notice Owner may set a specific nonce for a guest (administrative).
     * @param guest address of guest
     * @param newNonce new nonce value to set
     */
    function setGuestNonce(address guest, uint256 newNonce) external onlyOwner {
        nonces[guest] = newNonce;
        emit GuestRevoked(guest, newNonce);
    }

    /**
     * @notice Transfer contract ownership (admin functions restricted to owner)
     * @param newOwner address of new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "SignatureGate: zero owner");
        owner = newOwner;
    }

    /* ===================== View Helpers ===================== */

    /**
     * @notice Helper to compute the signed message hash off-chain equivalently.
     * @param guest address of guest (usually msg.sender when signing)
     * @param eventId numeric event id
     * @param nonce nonce used in signature
     * @return ethSignedHash the keccak256 hash wrapped by Ethereum Signed Message prefix
     */
    function computeEthSignedHash(address guest, uint256 eventId, uint256 nonce) external pure returns (bytes32) {
        bytes32 messageHash = keccak256(abi.encodePacked(guest, eventId, nonce));
        return messageHash.toEthSignedMessageHash();
    }
}
