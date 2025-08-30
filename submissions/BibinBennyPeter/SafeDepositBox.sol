// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IBasicBox {
  function storeSecret(string memory secret) external;
  function retrieveSecret() external view returns (string memory);
  function getOwner() external view returns (address);
}
interface IPremiumBox is IBasicBox{
  function transferOwnership(address newOwner) external;
}
interface ITimedBox is IBasicBox {
  function setLockTime(uint256 lockTime) external;
  function getLockTime() external view returns (uint256);
}

contract BasicBox is IBasicBox {
    string private secret;
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function storeSecret(string memory _secret) external override {
        require(msg.sender == owner, "Only owner can store secret");
        secret = _secret;
    }

    function retrieveSecret() external view override returns (string memory) {
        require(msg.sender == owner, "Only owner can retrieve secret");
        return secret;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }
}

contract PremiumBox is IPremiumBox {
    string private secret;
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function storeSecret(string memory _secret) external override {
        require(msg.sender == owner, "Only owner can store secret");
        secret = _secret;
    }

    function retrieveSecret() external view override returns (string memory) {
        require(msg.sender == owner, "Only owner can retrieve secret");
        return secret;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function transferOwnership(address newOwner) external override {
        require(msg.sender == owner, "Only owner can transfer ownership");
        owner = newOwner;
    }
}

contract TimedBox is ITimedBox {
    string private secret;
    address private owner;
    uint256 private lockTime;

    constructor() {
        owner = msg.sender;
    }

    function storeSecret(string memory _secret) external override {
        require(msg.sender == owner, "Only owner can store secret");
        secret = _secret;
    }

    function retrieveSecret() external view override returns (string memory) {
        require(msg.sender == owner, "Only owner can retrieve secret");
        require(block.timestamp >= lockTime, "Secret is locked");
        return secret;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function setLockTime(uint256 _lockTime) external override {
        require(msg.sender == owner, "Only owner can set lock time");
        lockTime = _lockTime;
    }

    function getLockTime() external view override returns (uint256) {
        return lockTime;
    }
}

contract VaultManager{
    
    address public immutable owner;
    mapping (address =>type2) name;
    constructor() {
        owner = msg.sender;
    }

    function createBasicBox() external returns (address) {
        require(msg.sender == owner, "Only owner can create BasicBox");
        BasicBox box = new BasicBox();
        return address(box);
    }

    function createPremiumBox() external returns (address) {
        require(msg.sender == owner, "Only owner can create PremiumBox");
        PremiumBox box = new PremiumBox();
        return address(box);
    }

    function createTimedBox() external returns (address) {
        require(msg.sender == owner, "Only owner can create TimedBox");
        TimedBox box = new TimedBox();
        return address(box);
    }

    function storeSecretToBox(address boxAddress, string memory secret) external {
        require(IBasicBox(boxAddress).getOwner() == msg.sender, "Not the owner of the box");
        IBasicBox(boxAddress).storeSecret(secret);
    }

    function retrieveSecretFromBox(address boxAddress) external view returns (string memory) {
        require(IBasicBox(boxAddress).getOwner() == msg.sender, "Not the owner of the box");
        return IBasicBox(boxAddress).retrieveSecret();
    }

    function getBoxOwner(address boxAddress) external view returns (address) {
        require(IBasicBox(boxAddress).getOwner() == msg.sender, "Not the owner of the box");
        return IBasicBox(boxAddress).getOwner();
    }

    function transferBoxOwnership(address boxAddress, address newOwner) external {
        require(IBasicBox(boxAddress).getOwner() == msg.sender, "Not the owner of the box");
        require(newOwner != address(0), "New owner cannot be zero address");
        IPremiumBox(boxAddress).transferOwnership(newOwner);
    }

    function setBoxLockTime(address boxAddress, uint256 lockTime) external {
        require(ITimedBox(boxAddress).getOwner() == msg.sender, "Not the owner of the box");
        ITimedBox(boxAddress).setLockTime(lockTime);
    }
}

