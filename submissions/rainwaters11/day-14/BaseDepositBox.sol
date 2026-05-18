// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {
    address private _owner;
    string private _secret;
    uint256 private _depositTime;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function getOwner() public view override returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        _owner = newOwner;
    }

    function storeSecret(string calldata secret) external virtual override onlyOwner {
            require(bytes(secret).length == 66, "Store hashed secret only");
            _secret = secret;
            _depositTime = block.timestamp;
        }

    function getSecret() public view virtual override onlyOwner returns (string memory) {
        return _secret;
    }

    function getBoxType() public pure virtual override returns (string memory) {
        return "BASE_DEPOSIT_BOX";
    }

    function getDepositTime() public view override returns (uint256) {
        return _depositTime;
    }
}
