// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SignThis {

    // Event for successful verification
    event Verified(address signer, string message);

    /*
     * Get message hash
     */
    function getMessageHash(string memory _message) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message));
    }

    /*
     * Get Ethereum signed message hash
     */
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );
    }

    /*
     * Recover signer address using signature
     */
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /*
     * Verify signature
     */
    function verify(
        address _signer,
        string memory _message,
        bytes memory _signature
    ) public returns (bool) {

        bytes32 messageHash = getMessageHash(_message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        address recovered = recoverSigner(ethSignedMessageHash, _signature);

        if (recovered == _signer) {
            emit Verified(_signer, _message);
            return true;
        }

        return false;
    }

    /*
     * Split signature into r, s, v
     */
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}