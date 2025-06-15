// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//还没弄懂
interface IDepositBox {
    function storeSecret(string calldata secret) external payable; // 添加 payable
    function getSecret() external view returns (string memory);
    function transferOwnership(address newOwner) external;
    function getOwner() external view returns (address);
}

contract BasicDepositBox is IDepositBox {
    address private _owner;
    string private _secret;

    constructor() {
        _owner = msg.sender;
    }

    function storeSecret(string calldata secret) external payable override {
        require(msg.value == 0); // 拒绝接收 ETH
        require(msg.sender == _owner);
        _secret = secret;
    }

    function getSecret() external view override returns (string memory) {
        return _secret;
    }

    function transferOwnership(address newOwner) external override {
        require(msg.sender == _owner);
        require(newOwner != address(0));
        _owner = newOwner;
    }

    function getOwner() external view override returns (address) {
        return _owner;
    }
}

contract PremiumDepositBox is IDepositBox {
    address private _owner;
    string private _secret;
    uint256 private constant FEE = 0.001 ether;

    constructor() payable {
        require(msg.value >= FEE);
        _owner = msg.sender;
    }

    function storeSecret(string calldata secret) external payable override {
        require(msg.value >= FEE);
        require(msg.sender == _owner);
        _secret = secret;
    }

    function getSecret() external view override returns (string memory) {
        return _secret;
    }

    function transferOwnership(address newOwner) external override {
        require(msg.sender == _owner);
        require(newOwner != address(0));
        _owner = newOwner;
    }

    function getOwner() external view override returns (address) {
        return _owner;
    }
}

contract TimeLockedDepositBox is IDepositBox {
    address private _owner;
    string private _secret;
    uint256 private _lockUntil;

    constructor(uint256 lockDuration) {
        _owner = msg.sender;
        _lockUntil = block.timestamp + lockDuration;
    }

    function storeSecret(string calldata secret) external payable override {
        require(msg.value == 0); // 拒绝接收 ETH
        require(msg.sender == _owner);
        require(block.timestamp >= _lockUntil);
        _secret = secret;
    }

    function getSecret() external view override returns (string memory) {
        return _secret;
    }

    function transferOwnership(address newOwner) external override {
        require(msg.sender == _owner);
        require(newOwner != address(0));
        _owner = newOwner;
    }

    function getOwner() external view override returns (address) {
        return _owner;
    }
}

contract VaultManager {
    mapping(address => address[]) private userDepositBoxes;
    mapping(address => address) private boxOwners;

    function createDepositBox(string memory boxType, uint256 param) external payable returns (address) {
        address newBox;
        if (keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked("Basic"))) {
            newBox = address(new BasicDepositBox());
        } else if (keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked("Premium"))) {
            require(msg.value >= 0.001 ether);
            newBox = address(new PremiumDepositBox{value: msg.value}());
        } else if (keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked("TimeLocked"))) {
            require(param > 0);
            newBox = address(new TimeLockedDepositBox(param));
        } else {
            revert();
        }

        boxOwners[newBox] = msg.sender;
        userDepositBoxes[msg.sender].push(newBox);
        return newBox;
    }

    function storeSecret(address depositBox, string calldata secret) external payable {
        require(boxOwners[depositBox] == msg.sender);
        IDepositBox(depositBox).storeSecret{value: msg.value}(secret);
    }

    function getSecret(address depositBox) external view returns (string memory) {
        require(boxOwners[depositBox] == msg.sender);
        return IDepositBox(depositBox).getSecret();
    }

    function transferBoxOwnership(address depositBox, address newOwner) external {
        require(boxOwners[depositBox] == msg.sender);
        IDepositBox(depositBox).transferOwnership(newOwner);
        boxOwners[depositBox] = newOwner;

        for (uint256 i = 0; i < userDepositBoxes[msg.sender].length; i++) {
            if (userDepositBoxes[msg.sender][i] == depositBox) {
                userDepositBoxes[msg.sender][i] = userDepositBoxes[msg.sender][userDepositBoxes[msg.sender].length - 1];
                userDepositBoxes[msg.sender].pop();
                break;
            }
        }

        userDepositBoxes[newOwner].push(depositBox);
    }

    function getUserDepositBoxes() external view returns (address[] memory) {
        return userDepositBoxes[msg.sender];
    }
}