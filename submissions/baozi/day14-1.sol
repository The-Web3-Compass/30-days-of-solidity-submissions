// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {
    address private _owner;
    string private _secret;
    uint256 private _depositTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretStored(address indexed owner, string maskedSecret);

    constructor() {
        _owner = msg.sender;
        _depositTime = block.timestamp;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "BaseDepositBox: caller is not the owner");
        _;
    }

    function getOwner() public view override returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "BaseDepositBox: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function storeSecret(string calldata _newSecret) external override onlyOwner {
        require(bytes(_newSecret).length > 0, "BaseDepositBox: secret cannot be empty");
        _secret = _newSecret;
        emit SecretStored(msg.sender, "***");
    }

    function getSecret() public view override onlyOwner returns (string memory) {
        return _secret;
    }

    function getDepositTime() external view override onlyOwner returns (uint256) {
        return _depositTime;
    }
}
