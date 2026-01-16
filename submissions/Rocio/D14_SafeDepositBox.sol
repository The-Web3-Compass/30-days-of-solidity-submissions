// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
// Note: Context is implicitly used by Ownable, but often good to explicitly import if needed

// --- 1. INTERFACE DEFINITION ---

/**
 * @title IDepositBox
 * @dev Defines the common interface for all types of deposit box contracts.
 * This interface mandates the functions required for the VaultManager to interact
 * with any box uniformly (store, retrieve, transfer).
 * NOTE: It DOES NOT inherit from Ownable to avoid linearization conflicts.
 */
interface IDepositBox {
    // Standard access and function signatures
    function getBoxType() external view returns (string memory);
    function storeSecret(bytes calldata _secret) external;
    function getSecret() external view returns (bytes memory);
    
    // Ownership functions (required by the interface standard)
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}

// --- 2. THE CENTRAL MANAGER CONTRACT ---

/**
 * @title VaultManager
 * @dev The central 'Bank' that manages and interacts with all deployed DepositBox contracts.
 * It acts as a factory and a unified entry point for users to manage their boxes.
 */
contract VaultManager is Ownable {
    // Mapping of user address to their primary DepositBox address
    mapping(address => IDepositBox) public userVaults;
    
    event BoxCreated(address indexed user, address indexed boxAddress, string boxType);
    event SecretStored(address indexed user, address indexed boxAddress);
    event OwnershipTransferred(address indexed boxAddress, address indexed oldOwner, address indexed newOwner);

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Creates a new deposit box of the specified type for the caller (msg.sender).
     * @param _boxType A string identifier for the type of box to create ("Basic" or "TimeLocked").
     * @param _unlockTimestamp Unix timestamp required for the TimeLocked box (0 for Basic).
     */
    function createDepositBox(string calldata _boxType, uint256 _unlockTimestamp) external {
        require(address(userVaults[msg.sender]) == address(0), "VaultManager: User already owns a box.");

        IDepositBox newBox;

        if (keccak256(bytes(_boxType)) == keccak256(bytes("Basic"))) {
            newBox = IDepositBox(new BasicDepositBox(msg.sender));
        } else if (keccak256(bytes(_boxType)) == keccak256(bytes("TimeLocked"))) {
            require(_unlockTimestamp > block.timestamp, "VaultManager: Timestamp must be in the future.");
            newBox = IDepositBox(new TimeLockedDepositBox(msg.sender, _unlockTimestamp));
        } else {
            revert("VaultManager: Invalid box type specified.");
        }

        userVaults[msg.sender] = newBox;
        emit BoxCreated(msg.sender, address(newBox), _boxType);
    }

    // --- Unified User Interaction Functions ---

    /**
     * @notice Allows the user to store a secret in their personal deposit box.
     * @param _secret The data (e.g., encrypted password, private key fragment) to store.
     * @dev Uses the interface to call the specific box implementation.
     */
    function storeMySecret(bytes calldata _secret) external {
        IDepositBox box = userVaults[msg.sender];
        require(address(box) != address(0), "VaultManager: User does not own a box.");
        
        // External call to the specific box implementation
        box.storeSecret(_secret);
        emit SecretStored(msg.sender, address(box));
    }

    /**
     * @notice Allows the user to retrieve their stored secret.
     */
    function retrieveMySecret() external view returns (bytes memory) {
        IDepositBox box = userVaults[msg.sender];
        require(address(box) != address(0), "VaultManager: User does not own a box.");

        // External view call
        return box.getSecret();
    }

    /**
     * @notice Transfers ownership of the user's deposit box to a new address.
     * @param _newOwner The address that will become the new owner of the box.
     * @dev The manager handles the mapping update, but the box enforces internal logic (like TimeLock).
     */
    function transferMyBoxOwnership(address _newOwner) external {
        IDepositBox box = userVaults[msg.sender];
        require(address(box) != address(0), "VaultManager: User does not own a box.");
        
        // 1. Call the external transferOwnership function defined by the IDepositBox interface.
        // The box logic (e.g., TimeLock) will execute here and revert if conditions aren't met.
        address oldOwner = box.owner();
        box.transferOwnership(_newOwner);
        
        // 2. Update manager mapping only after successful external transfer
        userVaults[_newOwner] = box;
        delete userVaults[msg.sender];

        emit OwnershipTransferred(address(box), oldOwner, _newOwner);
    }
}

// --- 3. CONCRETE BOX IMPLEMENTATION 1 (Basic) ---

/**
 * @title BasicDepositBox
 * @dev A simple deposit box with no constraints on transfer. Implements IDepositBox.
 */
contract BasicDepositBox is Ownable, IDepositBox { // FIX: Correct Inheritance Order: Base (Ownable) then Interface (IDepositBox)
    bytes private secretData;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function getBoxType() external pure override returns (string memory) {
        return "Basic";
    }

    // Storage and retrieval functions are restricted by onlyOwner inherited from Ownable
    function storeSecret(bytes calldata _secret) external override onlyOwner {
        secretData = _secret;
    }

    function getSecret() external view override onlyOwner returns (bytes memory) {
        return secretData;
    }

    function transferOwnership(address newOwner) public override(IDepositBox, Ownable) onlyOwner {
        // Standard OpenZeppelin ownership transfer logic
        _transferOwnership(newOwner);
    }
    
    // Explicitly override owner() to satisfy the IDepositBox interface requirement
    function owner() public view override(IDepositBox, Ownable) returns (address) {
        return Ownable.owner();
    }
}

// --- 4. CONCRETE BOX IMPLEMENTATION 2 (Time-Locked) ---

/**
 * @title TimeLockedDepositBox
 * @dev A box that locks ownership transfer until a specific timestamp is reached.
 */
contract TimeLockedDepositBox is Ownable, IDepositBox { // FIX: Correct Inheritance Order
    bytes private secretData;
    uint256 public immutable unlockTimestamp;

    constructor(address initialOwner, uint256 _unlockTimestamp) Ownable(initialOwner) {
        unlockTimestamp = _unlockTimestamp;
    }

    function getBoxType() external pure override returns (string memory) {
        return "TimeLocked";
    }

    function storeSecret(bytes calldata _secret) external override onlyOwner {
        secretData = _secret;
    }

    function getSecret() external view override onlyOwner returns (bytes memory) {
        return secretData;
    }

    function transferOwnership(address newOwner) public override(IDepositBox, Ownable) onlyOwner {
        // Core Constraint: Transfer is ONLY possible after the lock time has passed.
        require(block.timestamp >= unlockTimestamp, "TimeLockedBox: Ownership is time-locked.");
        _transferOwnership(newOwner);
    }
    
    function owner() public view override(IDepositBox, Ownable) returns (address) {
        return Ownable.owner();
    }
}