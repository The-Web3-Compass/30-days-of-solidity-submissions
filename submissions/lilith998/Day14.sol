// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Common interface for all deposit boxes
interface IDepositBox {
    function storeSecret(bytes32 secret) external;
    function retrieveSecret() external view returns (bytes32);
    function transferOwnership(address newOwner) external;
    function getOwner() external view returns (address);
    function getType() external pure returns (string memory);
}

// Base contract with common functionality
abstract contract BaseDepositBox is IDepositBox {
    address private _owner;
    bytes32 private _secret;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretUpdated(address indexed owner);
    
    constructor(address initialOwner) {
        _owner = initialOwner;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can access");
        _;
    }
    
    function getOwner() public view override returns (address) {
        return _owner;
    }
    
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    function storeSecret(bytes32 secret) public virtual override onlyOwner {
        _secret = secret;
        emit SecretUpdated(msg.sender);
    }
    
    function retrieveSecret() public view virtual override onlyOwner returns (bytes32) {
        return _secret;
    }
    
    function getType() public pure virtual override returns (string memory);
}

// Basic Deposit Box - No restrictions
contract BasicDepositBox is BaseDepositBox {
    constructor(address initialOwner) BaseDepositBox(initialOwner) {}
    
    function getType() public pure override returns (string memory) {
        return "Basic";
    }
}

// Premium Deposit Box - Only owner can store once
contract PremiumDepositBox is BaseDepositBox {
    bool private _secretStored;
    
    constructor(address initialOwner) BaseDepositBox(initialOwner) {}
    
    function storeSecret(bytes32 secret) public override onlyOwner {
        require(!_secretStored, "Premium: Secret already stored");
        super.storeSecret(secret);
        _secretStored = true;
    }
    
    function getType() public pure override returns (string memory) {
        return "Premium";
    }
}

// Time-Locked Deposit Box - Secret retrievable only after lock period
contract TimeLockedDepositBox is BaseDepositBox {
    uint256 private immutable _unlockTime;
    
    constructor(address initialOwner, uint256 lockDays) BaseDepositBox(initialOwner) {
        _unlockTime = block.timestamp + (lockDays * 1 days);
    }
    
    function retrieveSecret() public view override onlyOwner returns (bytes32) {
        require(block.timestamp >= _unlockTime, "TimeLocked: Funds locked");
        return super.retrieveSecret();
    }
    
    function getUnlockTime() public view returns (uint256) {
        return _unlockTime;
    }
    
    function getType() public pure override returns (string memory) {
        return "TimeLocked";
    }
}

// Main Vault Manager
contract VaultManager {
    mapping(address => address[]) private userDepositBoxes;
    mapping(address => address) private boxOwners;
    
    event DepositBoxCreated(
        address indexed owner, 
        address indexed boxAddress,
        string boxType
    );
    
    // Create a new deposit box
    function createDepositBox(
        string memory boxType,
        uint256 lockDays
    ) external returns (address newBox) {
        if (keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked("Basic"))) {
            newBox = address(new BasicDepositBox(msg.sender));
        } else if (keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked("Premium"))) {
            newBox = address(new PremiumDepositBox(msg.sender));
        } else if (keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked("TimeLocked"))) {
            require(lockDays > 0, "Lock period required");
            newBox = address(new TimeLockedDepositBox(msg.sender, lockDays));
        } else {
            revert("Invalid box type");
        }
        
        userDepositBoxes[msg.sender].push(newBox);
        boxOwners[newBox] = msg.sender;
        emit DepositBoxCreated(msg.sender, newBox, boxType);
    }
    
    // Get all deposit boxes for a user
    function getUserDepositBoxes(address user) external view returns (address[] memory) {
        return userDepositBoxes[user];
    }
    
    // Unified interface for deposit box operations
    function storeSecretToBox(address boxAddress, bytes32 secret) external {
        require(boxOwners[boxAddress] == msg.sender, "Not box owner");
        IDepositBox(boxAddress).storeSecret(secret);
    }
    
    function retrieveSecretFromBox(address boxAddress) external view returns (bytes32) {
        require(boxOwners[boxAddress] == msg.sender, "Not box owner");
        return IDepositBox(boxAddress).retrieveSecret();
    }
    
    function transferBoxOwnership(address boxAddress, address newOwner) external {
        require(boxOwners[boxAddress] == msg.sender, "Not box owner");
        IDepositBox(boxAddress).transferOwnership(newOwner);
        
        // Update ownership tracking
        boxOwners[boxAddress] = newOwner;
        
        // Update user box lists
        removeBoxFromUser(msg.sender, boxAddress);
        userDepositBoxes[newOwner].push(boxAddress);
    }
    
    // Helper function to remove box from user's list
    function removeBoxFromUser(address user, address boxAddress) private {
        address[] storage boxes = userDepositBoxes[user];
        for (uint i = 0; i < boxes.length; i++) {
            if (boxes[i] == boxAddress) {
                boxes[i] = boxes[boxes.length - 1];
                boxes.pop();
                break;
            }
        }
    }
    
    // Get deposit box metadata
    function getBoxMetadata(address boxAddress) external view returns (
        address owner,
        string memory boxType,
        uint256 unlockTime
    ) {
        owner = IDepositBox(boxAddress).getOwner();
        boxType = IDepositBox(boxAddress).getType();
        
        if (keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked("TimeLocked"))) {
            unlockTime = TimeLockedDepositBox(boxAddress).getUnlockTime();
        } else {
            unlockTime = 0;
        }
        
        return (owner, boxType, unlockTime);
    }
}