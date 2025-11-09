//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day14-IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {
    address private owner;
    string private secret;
    uint256 private boxCreatedTime;

    event OwnerTransferred(address indexed preOwner, address indexed newOwner);
    event SecretStored(address indexed owner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
        boxCreatedTime = block.timestamp;
    }

    function getOwner() external view override returns(address) {
        return owner;
    }

    function transferOwner(address _newOwner) external virtual override onlyOwner {
        require(address(0) != _newOwner, "Invalide address");
        address preOwner = owner;
        owner = _newOwner;
        emit OwnerTransferred(preOwner, owner);
    }

    function storeSecret(string calldata _secret) external virtual override onlyOwner {
        secret = _secret;
        emit SecretStored(owner);
    }

    function getSecret() public view virtual override onlyOwner returns(string memory) {
        return secret;
    }

    function getBoxCreatedTime() external view virtual override returns(uint256) {
        return boxCreatedTime;
    }
}