// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SignatureGate {
    address public organizer; // signer address (event organizer)
    mapping(bytes32 => bool) public used; // used signatures (by hash)

    event EntryGranted(address indexed attendee, uint256 indexed eventId, uint256 nonce);
    event OrganizerChanged(address oldOrganizer, address newOrganizer);

    error InvalidSignature();
    error SignatureExpired();
    error SignatureAlreadyUsed();
    error NotOrganizer();

    constructor(address _organizer) {
        require(_organizer != address(0), "organizer zero");
        organizer = _organizer;
    }

    function setOrganizer(address _new) external {
        if (msg.sender != organizer) revert NotOrganizer();
        emit OrganizerChanged(organizer, _new);
        organizer = _new;
    }

    function claim(
        uint256 eventId,
        uint256 expiry,
        uint256 nonce,
        bytes calldata sig
    ) external {
        if (expiry != 0 && block.timestamp > expiry) revert SignatureExpired();

        bytes32 digest = _hashForSigning(msg.sender, eventId, expiry, nonce);

        if (used[digest]) revert SignatureAlreadyUsed();

        address signer = _recover(digest, sig);
        if (signer != organizer) revert InvalidSignature();

        used[digest] = true;

        emit EntryGranted(msg.sender, eventId, nonce);
    }

    function hashForSigning(
        address attendee,
        uint256 eventId,
        uint256 expiry,
        uint256 nonce
    ) external pure returns (bytes32) {
        return _hashForSigning(attendee, eventId, expiry, nonce);
    }

    function _hashForSigning(
        address attendee,
        uint256 eventId,
        uint256 expiry,
        uint256 nonce
    ) internal pure returns (bytes32) {
        bytes32 raw = keccak256(abi.encodePacked("\x19Event Entry:\n", attendee, eventId, expiry, nonce));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", raw));
    }

    function _recover(bytes32 digest, bytes memory sig) internal pure returns (address) {
        if (sig.length != 65) return address(0);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }
        if (v < 27) v += 27;
        return ecrecover(digest, v, r, s);
    }
}
