// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IDepositBox {
    function storeSecret(string calldata secret) external;

    function getSecret() external view returns (string memory);

    function transferOwnership(address newOwner) external;

    function getOwner() external view returns (address);

    function getBoxType() external view returns (string memory);
}

// Abstract base contract to manage ownership logic
abstract contract VaultBox {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not a owner!");
        _;
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "invalid address!");
        require(newOwner != owner, "New owner must be different");

        address previousOwner = owner;
        owner = newOwner;
    }
}

contract SafeDepositBox is VaultBox, IDepositBox {
    string private S_Secret;

    constructor() VaultBox(msg.sender) {}

    function storeSecret(string calldata secret) external override onlyOwner {
        S_Secret = secret;
    }

    function getSecret()
        external
        view
        override
        onlyOwner
        returns (string memory)
    {
        return S_Secret;
    }

    function transferOwnership(
        address newOwner
    ) external override(IDepositBox, VaultBox) onlyOwner {
        require(newOwner != address(0), "invalid address!");
        require(newOwner != owner, "New owner must be different");

        address previousOwner = owner;
        owner = newOwner;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function getBoxType() external pure override returns (string memory) {
        return "Basic";
    }
}

// Premium deposit box with additional features
contract PremiumDepositBox is VaultBox, IDepositBox {
    string private s_Secret;
    uint256 public accessCount;
    uint256 public lastAccessTime;

    constructor() VaultBox(msg.sender) {}

    function storeSecret(string calldata secret) external override onlyOwner {
        s_Secret = secret;
        accessCount++; // Tracks how many times the secret has been stored
        lastAccessTime = block.timestamp;
    }

    function getSecret()
        external
        view
        override
        onlyOwner
        returns (string memory)
    {
        return s_Secret;
    }

    function transferOwnership(
        address newOwner
    ) external override(IDepositBox, VaultBox) onlyOwner {
        require(newOwner != address(0), "invalid address!");
        require(newOwner != owner, "New owner must be different");

        address previousOwner = owner;
        owner = newOwner;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function getBoxType() external pure override returns (string memory) {
        return "Premium";
    }

    function getAccessStats()
        external
        view
        onlyOwner
        returns (uint256, uint256)
    {
        return (accessCount, lastAccessTime);
    }
}

// Time-locked deposit box
contract TimeLockedDepositBox is VaultBox, IDepositBox {
    string private s_Secret;
    uint256 public unlockTime;

    constructor(uint256 lockDuration) VaultBox(msg.sender) {
        unlockTime = block.timestamp + lockDuration;
    }

    modifier onlyWhenUnlocked() {
        require(block.timestamp >= unlockTime, "Box is still locked");
        _;
    }

    function storeSecret(string calldata secret) external override onlyOwner {
        s_Secret = secret;
    }

    function getSecret()
        external
        view
        override
        onlyOwner
        onlyWhenUnlocked
        returns (string memory)
    {
        return s_Secret;
    }

    function transferOwnership(
        address newOwner
    ) external override(IDepositBox, VaultBox) onlyOwner {
        require(newOwner != address(0), "invalid address!");
        require(newOwner != owner, "New owner must be different");

        address previousOwner = owner;
        owner = newOwner;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function getBoxType() external pure override returns (string memory) {
        return "TimeLocked";
    }

    function getRemainingLockTime() external view returns (uint256) {
        if (block.timestamp >= unlockTime) {
            return 0;
        }
        return unlockTime - block.timestamp;
    }
}

// Central manager - handles different box types through unified interface
contract VaultManager {
    mapping(address => IDepositBox[]) public userBoxes;
    mapping(string => uint256) public boxTypeCounts;

    event DepositBoxCreated(address indexed user, address box, string boxType);

    function createSafeDepositBox() external {
        IDepositBox newBox = new SafeDepositBox();
        userBoxes[msg.sender].push(newBox);
        boxTypeCounts["Basic"]++;
        emit DepositBoxCreated(msg.sender, address(newBox), "Basic");
    }

    function createPremiumDepositBox() external {
        IDepositBox newBox = new PremiumDepositBox();
        userBoxes[msg.sender].push(newBox);
        boxTypeCounts["Premium"]++;
        emit DepositBoxCreated(msg.sender, address(newBox), "Premium");
    }

    function createTimeLockedDepositBox(uint256 lockDuration) external {
        IDepositBox newBox = new TimeLockedDepositBox(lockDuration);
        userBoxes[msg.sender].push(newBox);
        boxTypeCounts["TimeLocked"]++;
        emit DepositBoxCreated(msg.sender, address(newBox), "TimeLocked");
    }

    function getUserBoxes(
        address user
    ) external view returns (IDepositBox[] memory) {
        return userBoxes[user];
    }

    // Demonstrates unified interaction through interface
    function getBoxInfo(
        address user,
        uint256 boxIndex
    )
        external
        view
        returns (address boxAddress, address boxOwner, string memory boxType)
    {
        require(boxIndex < userBoxes[user].length, "Box index out of bounds");
        IDepositBox box = userBoxes[user][boxIndex];

        return (address(box), box.getOwner(), box.getBoxType());
    }

    function getTotalBoxesByType(
        string memory boxType
    ) external view returns (uint256) {
        return boxTypeCounts[boxType];
    }
}
