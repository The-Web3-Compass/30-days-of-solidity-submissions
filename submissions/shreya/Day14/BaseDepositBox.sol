// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {
    address internal _owner;
    string private _secret;
    uint256 internal _depositTime;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function getOwner() public view virtual override returns (address) {
        return _owner;
    }

    function getDepositTime() public view virtual override returns (uint256) {
        return _depositTime;
    }

    function storeSecret(string calldata secret) public virtual override onlyOwner {
        _secret = secret;
        _depositTime = block.timestamp;
    }

    function getSecret() public view virtual override onlyOwner returns (string memory) {
        return _secret;
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        _owner = newOwner;
    }
}