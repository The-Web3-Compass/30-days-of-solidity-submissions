// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SignThis
 * @dev Build a secure signature-based entry system for a private Web3 event,
 * like a conference, workshop, or token-gated meetup.
 * Instead of storing an on-chain whitelist of attendees,
 * your backend or event organizer signs a message for each approved guest.
 * When attendees arrive, they submit their signed message to the smart contract to prove they were invited.
 * The contract uses `ecrecover` to verify the signature on-chain,
 * confirming their identity without needing any prior on-chain registration.
 * This pattern drastically reduces gas costs, keeps the contract lightweight,
 * and mirrors how many real-world events handle off-chain approvals with on-chain validation —
 * a practical Web3 authentication flow.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 19
 */
abstract contract SignThis is Ownable {
    constructor() Ownable(msg.sender) {}

    /**
     * Process the message hash and message signature, the use ecrecover to extract the signer account
     */
    function recoverSigner(bytes32 msgHash, bytes memory msgSig)
        public
        pure
        returns (address)
    {
        require(msgSig.length == 65, "signature length invalid");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(msgSig, 32))
            s := mload(add(msgSig, 64))
            v := byte(0, mload(add(msgSig, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "signature 'v' invalid");

        return ecrecover(msgHash, v, r, s);
    }

    function getSignedMsgHash(bytes32 msgHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
    }

    function verifySig(bytes32 msgHash, bytes memory sig) public view returns (bool) {
        bytes32 signedMsgHash = getSignedMsgHash(msgHash);
        return (recoverSigner(signedMsgHash, sig)) == owner();
    }
}
