// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {
    address private owner;
    string private secret;
    uint256 private depositTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SecretStored(address indexed owner);

    constructor(address _owner) {
        owner = _owner;
        depositTime = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function transferOwnership(
        address newOwner
    ) external virtual override onlyOwner {
        require(owner != address(0), "Invalid address");
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }

    function storeSecret(
        string calldata _secret
    ) external virtual override onlyOwner {
        // require(bytes(_secret).length < 32, "You need to input a shorter secret ");
        secret = _secret;
        emit SecretStored(msg.sender);
    }

    function getSecret()
        public
        view
        virtual
        override
        onlyOwner
        returns (string memory)
    {
        return secret;
    }

    function getDepositTime()
        external
        view
        virtual
        override
        onlyOwner
        returns (uint256)
    {
        return depositTime;
    }
}
