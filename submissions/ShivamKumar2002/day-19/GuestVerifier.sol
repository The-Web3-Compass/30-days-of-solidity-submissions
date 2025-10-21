// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GuestVerifier
 * @author shivam
 * @notice A contract to verify guest entry for an event using EIP-712 signatures.
 * @dev Allows an owner (event organizer) to sign messages off-chain for guests.
 * @dev Guests submit the signature on-chain to verify their invitation without an on-chain whitelist.
 */
contract GuestVerifier {
    /// @notice Struct representing the EIP-712 Domain.
    /// @dev Used to calculate the EIP-712 Domain Separator.
    struct EIP712Domain {
        /// @notice Domain name (e.g., "GuestVerifier").
        string  name;
        /// @notice Domain version (e.g., "1").
        string  version;
        /// @notice Chain ID where the contract is deployed.
        uint256 chainId;
        /// @notice Address of this contract.
        address verifyingContract;
    }

    /// @notice Struct representing a guest's invitation data, used to create an EIP-712 signature.
    struct GuestApproval {
        /// @notice Address of the guest.
        address guest;
        /// @notice ID of the event the guest is trying to enter.
        uint256 eventId;
    }

    // --- State Variables ---

    /// @notice The name of the contract.
    string public constant name = "GuestVerifier";

    /// @notice The version of the contract.
    string public constant version = "1";

    /// @notice EIP-712 Type Hash for the EIP712Domain struct
    bytes32 private constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 private constant GUEST_APPROVAL_TYPEHASH = keccak256("GuestApproval(address guest,uint256 eventId)");

    /// @notice EIP-712 Domain Separator
    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @notice Address of the contract owner (event organizer).
    address public owner;
    
    /// @notice Flag indicating if guest verification is currently enabled.
    bool public isEntryOpen;

    // --- Events ---

    /// @notice Emitted when a guest's signature is successfully verified.
    /// @param guest The address of the verified guest.
    /// @param eventId The ID of the event for which the guest was verified.
    event GuestVerified(address indexed guest, uint256 eventId);

    /// @notice Emitted when the contract ownership is transferred.
    /// @param previousOwner The address of the previous owner.
    /// @param newOwner The address of the new owner.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Emitted when the event entry status is changed by the owner.
    /// @param isOpen The new status of event entry (true = open, false = closed).
    event EntryStatusChanged(bool isOpen);

    // --- Custom Errors ---

    /// @notice Error thrown when caller is not the owner.
    error NotOwner();

    /// @notice Error thrown when entry is not open.
    error EntryNotOpen();

    /// @notice Error thrown when the signature length is not 65 bytes.
    /// @param length The actual length of the provided signature.
    error InvalidSignatureLength(uint256 length);

    /// @notice Error thrown when the recovered signer address does not match the owner address.
    /// @param recovered The address recovered from the signature.
    error InvalidSigner(address recovered);

    // --- Modifiers ---

    /// @notice Modifier to restrict function calls to the owner.
    /// @custom:error NotOwner if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // --- Constructor ---

    /**
     * @notice Initializes the contract, setting the deployer as owner and calculating EIP-712 constants.
     * @dev Entry is closed by default upon deployment.
     */
    constructor() {
        owner = msg.sender;

        DOMAIN_SEPARATOR = _calculateDomainSeparator();
        
        emit OwnershipTransferred(address(0), owner);
        emit EntryStatusChanged(isEntryOpen);
    }

    // --- EIP-712 Helper Functions ---

    /// @notice Calculates the EIP-712 domain separator.
    /// @return domainSeparator The EIP-712 domain separator.
    function _calculateDomainSeparator() private view returns (bytes32 domainSeparator) {
        domainSeparator = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @notice Calculates the EIP-712 hash of the structured guest verification data.
     * @param _guestApproval The guest's approval data.
     * @return dataHash The EIP-712 hash of the GuestApproval struct.
     */
    function _hashGuestApproval(GuestApproval memory _guestApproval) internal pure returns (bytes32 dataHash) {
        dataHash = keccak256(
            abi.encode(
                GUEST_APPROVAL_TYPEHASH,
                _guestApproval.guest,
                _guestApproval.eventId
            )
        );
    }

    /**
     * @notice Calculates the final EIP-712 digest of given dataHash.
     * @dev Follows EIP-712 specification: `keccak256("\x19\x01" + DOMAIN_SEPARATOR + dataHash)`.
     * @param dataHash The EIP-712 structHash.
     * @return digest The EIP-712 digest (hash of domain separator and data hash).
     */
    function _calculateEIP712Digest(bytes32 dataHash) internal view returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, dataHash));
    }

    /**
     * @notice Calculates the EIP-712 digest for a guest's approval.
     * @param _guest The guest's address.
     * @param _eventId The event ID.
     * @return digest The EIP-712 digest.
     */
    function calculateGuestApprovalDigest(address _guest, uint256 _eventId) internal view returns (bytes32 digest) {
        bytes32 dataHash = _hashGuestApproval(GuestApproval({guest: _guest, eventId: _eventId}));
        digest = _calculateEIP712Digest(dataHash);
    }

    // --- Core Verification Logic ---

    /**
     * @notice Verifies a guest's signature for a specific event.
     * @param _guest The address of the guest trying to enter the event.
     * @param _eventId The ID of the event the guest is trying to enter.
     * @param _signature The EIP-712 signature (`r`, `s`, `v`) provided by the guest.
     * @dev Recovers the signer address from the EIP-712 signature and checks if it matches the owner.
     * @custom:error EntryNotOpen If `isEntryOpen` is false.
     * @custom:error InvalidSigner If the recovered signer is not the contract owner.
     */
    function verifyGuest(address _guest, uint256 _eventId, bytes memory _signature) external {
        if (!isEntryOpen) revert EntryNotOpen();

        // Calculate the EIP-712 digest that should have been signed
        bytes32 digest = calculateGuestApprovalDigest(_guest, _eventId);

        // Recover the signer's address
        address signer = _recoverSigner(digest, _signature);

        // Verify the signer
        if (signer != owner) revert InvalidSigner(signer);

        // Emit event
        emit GuestVerified(_guest, _eventId);
    }

    /**
     * @dev Recovers the signer address from an EIP-712 signature (`r`, `s`, `v`).
     * @param _digest The EIP-712 digest that was signed.
     * @param _signature The 65-byte signature.
     * @return signer The address of the account that signed the digest. Returns address(0) on failure.
     * @custom:error InvalidSignatureLength If `_signature.length` is not 65.
     */
    function _recoverSigner(bytes32 _digest, bytes memory _signature) private pure returns (address signer) {
        // Check signature length
        if (_signature.length != 65) revert InvalidSignatureLength(_signature.length);

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature into r, s, and v components
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        // Adjust v to be 27 or 28
        if (v < 27) v += 27;

        // Use `ecrecover` precompile
        signer = ecrecover(_digest, v, r, s);
    }

    // --- Owner Functions ---

    /**
     * @notice Allows the owner to open or close event entry.
     * @param _isOpen The desired status for event entry (true = open, false = closed).
     */
    function setEntryStatus(bool _isOpen) external onlyOwner {
        if (_isOpen == isEntryOpen) {
            return;
        }
        isEntryOpen = _isOpen;
        emit EntryStatusChanged(_isOpen);
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev Can only be called by the current owner.
     * @param newOwner The address to transfer ownership to.
     * @custom:error ZeroAddress If `newOwner` is the zero address.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "newOwner cannot be the zero address");
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
}