// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title SignThis
/// @notice A secure signature-based entry system for private Web3 events using ecrecover for on-chain verification.
/// @dev Verifies off-chain signed messages to authenticate attendees without storing a whitelist on-chain.
/// @author Antonio Quental
/// @custom:dev-run-script scripts/SignThisScript.ts
contract SignThis {
    /// @notice Address of the event organizer authorized to sign messages.
    /// @dev Only this address can issue valid signatures for entry.
    address public immutable organizer;

    /// @notice Mapping to track used signatures to prevent reuse.
    /// @dev Maps the hash of the signed message to its usage status.
    mapping(bytes32 => bool) public usedSignatures;

    /// @notice Emitted when an attendee successfully enters the event.
    /// @param attendee The address of the attendee who gained entry.
    /// @param messageHash The hash of the signed message used for entry.
    event EntryGranted(address indexed attendee, bytes32 indexed messageHash);

    /// @notice Emitted when an invalid signature is provided.
    /// @param attendee The address attempting entry.
    /// @param messageHash The hash of the invalid signed message.
    event InvalidSignature(
        address indexed attendee,
        bytes32 indexed messageHash
    );

    /// @notice Constructor sets the organizer address.
    /// @dev Initializes the contract with the event organizer's address.
    /// @param _organizer The address authorized to sign entry messages.
    constructor(address _organizer) {
        require(_organizer != address(0), "Invalid organizer address");
        organizer = _organizer;
    }

    /// @notice Verifies a signed message and grants entry if valid.
    /// @dev Uses ecrecover to verify the signature and checks for replay attacks.
    /// @param _message The message signed by the organizer (typically includes attendee address and event details).
    /// @param _signature The signature of the message, signed by the organizer.
    function enterEvent(
        bytes memory _message,
        bytes memory _signature
    ) external {
        // Hash the message to match the signed data
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                uint2str(_message.length),
                _message
            )
        );

        // Check if the signature has been used to prevent replay attacks
        require(!usedSignatures[messageHash], "Signature already used");

        // Recover the signer address using ecrecover
        address signer = recoverSigner(messageHash, _signature);

        // Verify the signer is the organizer
        if (signer == organizer) {
            // Mark the signature as used
            usedSignatures[messageHash] = true;

            // Emit success event
            emit EntryGranted(msg.sender, messageHash);
        } else {
            // Emit failure event
            emit InvalidSignature(msg.sender, messageHash);
            revert("Invalid signature");
        }
    }

    /// @notice Recovers the signer address from a message hash and signature.
    /// @dev Internal function to handle ecrecover logic securely.
    /// @param _messageHash The hash of the signed message.
    /// @param _signature The signature to recover the signer from.
    /// @return The address of the signer.
    function recoverSigner(
        bytes32 _messageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Extract r, s, v from the signature
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        // Adjust v if necessary (some clients return 0/1 instead of 27/28)
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid v value");

        // Recover and return the signer
        address signer = ecrecover(_messageHash, v, r, s);
        require(signer != address(0), "Invalid signer");
        return signer;
    }

    /// @notice Converts a uint to a string for message length prefixing.
    /// @dev Internal utility function for constructing the Ethereum signed message prefix.
    /// @param _num The number to convert.
    /// @return The string representation of the number.
    function uint2str(uint _num) internal pure returns (string memory) {
        if (_num == 0) {
            return "0";
        }
        uint j = _num;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_num != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_num - (_num / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _num /= 10;
        }
        return string(bstr);
    }
}
