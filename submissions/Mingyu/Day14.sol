// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IDepositBox Interface
interface IDepositBox {
    function getOwner() external view returns (address);
    function transferOwnership(address newOwner) external;
    function storeSecret(string calldata secret) external;
    function getSecret() external view returns (string memory);
    function getBoxType() external pure returns (string memory);
    function getDepositTime() external view returns (uint256);
}

// BaseDepositBox Contract
abstract contract BaseDepositBox is IDepositBox {
    address private owner;
    string private secret;
    uint256 private depositTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretStored(address indexed owner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the box owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    function getOwner() public view override returns (address) {
        return owner;
    }

    function transferOwnership(address newOwner) external virtual override onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function storeSecret(string calldata _secret) external virtual override onlyOwner {
        secret = _secret;
        emit SecretStored(msg.sender);
    }

    function getSecret() public view virtual override onlyOwner returns (string memory) {
        return secret;
    }

    function getDepositTime() external view virtual override returns (uint256) {
        return depositTime;
    }
}

// AdvancedDepositBox Contract
contract AdvancedDepositBox is BaseDepositBox {
    uint256 private expirationTime;
    bool private secretRevealed;

    event SecretRevealed(address indexed owner);

    constructor(uint256 _expirationDuration) {
        expirationTime = block.timestamp + _expirationDuration;
        secretRevealed = false;
    }

    // Overriding to return custom box type
    function getBoxType() public pure override returns (string memory) {
        return "Advanced Deposit Box";
    }

    // Method to reveal the secret after expiration
    function revealSecret() external onlyOwner {
        require(block.timestamp >= expirationTime, "Secret is still locked");
        require(!secretRevealed, "Secret already revealed");

        secretRevealed = true;
        emit SecretRevealed(msg.sender);
    }

    // Overriding to include secret revelation
    function getSecret() public view override onlyOwner returns (string memory) {
        require(secretRevealed, "Secret not yet revealed");
        return super.getSecret();
    }
}

// TimeLockedDepositBox Contract
contract TimeLockedDepositBox is BaseDepositBox {
    uint256 private unlockTime;

    event SecretUnlocked(address indexed owner);

    constructor(uint256 _unlockDuration) {
        unlockTime = block.timestamp + _unlockDuration;
    }

    // Overriding to return custom box type
    function getBoxType() public pure override returns (string memory) {
        return "Time-Locked Deposit Box";
    }

    // Method to unlock secret after a specified duration
    function unlockSecret() external onlyOwner {
        require(block.timestamp >= unlockTime, "Secret is still locked");

        emit SecretUnlocked(msg.sender);
    }

    // Overriding to include time lock on secret retrieval
    function getSecret() public view override onlyOwner returns (string memory) {
        require(block.timestamp >= unlockTime, "Secret is still locked");
        return super.getSecret();
    }
}

// VaultManager Contract to Manage Vault Creation
contract VaultManager {
    mapping(address => address[]) public userVaults;

    event VaultCreated(address indexed user, address vault);

    // Function to create an advanced deposit box
    function createAdvancedVault(uint256 _expirationDuration) external {
        AdvancedDepositBox newVault = new AdvancedDepositBox(_expirationDuration);
        userVaults[msg.sender].push(address(newVault));
        emit VaultCreated(msg.sender, address(newVault));
    }

    // Function to create a time-locked deposit box
    function createTimeLockedVault(uint256 _unlockDuration) external {
        TimeLockedDepositBox newVault = new TimeLockedDepositBox(_unlockDuration);
        userVaults[msg.sender].push(address(newVault));
        emit VaultCreated(msg.sender, address(newVault));
    }

    // Function to get all vaults owned by a user
    function getUserVaults(address user) external view returns (address[] memory) {
        return userVaults[user];
    }
}
