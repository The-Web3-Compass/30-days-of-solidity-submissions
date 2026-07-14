// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SignThis {

    address public signer;

    uint256 constant HALF_CURVE_ORDER = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;
    event SignatureVerified(string message);
    constructor(address _signer) {
        require(_signer != address(0), "Signer address cannot be zero");
        signer = _signer;
    }

    function verifySignature(bytes32 _messageHash, uint8 _v, bytes32 _r, bytes32 _s) public returns (bool) {
        require(_v == 27 || _v == 28, "Invalid v");
        require(uint256(_s) <= HALF_CURVE_ORDER, "Invalid s");

        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
        address recoveredSigner = ecrecover(prefixedHash, _v, _r, _s);

        if(recoveredSigner == signer) {
            emit SignatureVerified("Signature is valid");
            return true;
        } else {
            emit SignatureVerified("Signature is invalid");
            return false;
        }
    }
}
