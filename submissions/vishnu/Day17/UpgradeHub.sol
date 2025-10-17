// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISubscriptionLogic.sol";

/**
 * @title UpgradeHub
 * @dev Upgradeable proxy contract for subscription management
 * This contract stores all data and delegates logic execution to implementation contracts
 */
contract UpgradeHub {
    // ==================== STORAGE LAYOUT ====================
    // CRITICAL: This storage layout must NEVER change in future versions
    // New variables should always be appended at the end
    
    // Slot 0-2: Admin and upgrade control
    address public admin;
    address public pendingAdmin;
    address public implementation;
    
    // Slot 3-5: Contract state
    bool public paused;
    uint256 public totalPlans;
    uint256 public totalSubscriptions;
    
    // Slot 6+: Mappings and dynamic data
    mapping(uint256 => ISubscriptionLogic.Plan) public plans;
    mapping(uint256 => ISubscriptionLogic.Subscription) public subscriptions;
    mapping(address => uint256[]) public userSubscriptions;
    mapping(address => mapping(uint256 => bool)) public hasActivePlan;
    mapping(uint256 => uint256) public planSubscriberCount;
    mapping(address => uint256) public userTotalSpent;
    
    // Upgrade tracking
    mapping(address => bool) public approvedImplementations;
    address[] public implementationHistory;
    mapping(address => uint256) public implementationVersion;
    
    // Revenue tracking
    uint256 public totalRevenue;
    mapping(uint256 => uint256) public planRevenue;
    
    // ==================== EVENTS ====================
    
    event ImplementationUpgraded(
        address indexed oldImplementation,
        address indexed newImplementation,
        uint256 version
    );
    
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event ContractPaused(address indexed admin);
    event ContractUnpaused(address indexed admin);
    
    // Business logic events (emitted by implementation contracts)
    event PlanCreated(uint256 indexed planId, string name, uint256 price, uint256 duration);
    event SubscriptionCreated(
        uint256 indexed subscriptionId,
        address indexed subscriber,
        uint256 indexed planId,
        uint256 amount
    );
    event SubscriptionRenewed(uint256 indexed subscriptionId, uint256 newEndTime);
    event SubscriptionCanceled(uint256 indexed subscriptionId);
    event PlanUpgraded(
        uint256 indexed subscriptionId,
        uint256 indexed oldPlanId,
        uint256 indexed newPlanId
    );
    
    // ==================== MODIFIERS ====================
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "UpgradeHub: caller is not admin");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "UpgradeHub: contract is paused");
        _;
    }
    
    modifier validImplementation() {
        require(implementation != address(0), "UpgradeHub: no implementation set");
        require(approvedImplementations[implementation], "UpgradeHub: implementation not approved");
        _;
    }
    
    // ==================== CONSTRUCTOR ====================
    
    constructor(address _implementation) {
        require(_implementation != address(0), "UpgradeHub: invalid implementation");
        
        admin = msg.sender;
        implementation = _implementation;
        approvedImplementations[_implementation] = true;
        implementationHistory.push(_implementation);
        
        // Get version from implementation
        try ISubscriptionLogic(_implementation).getVersion() returns (uint256 version) {
            implementationVersion[_implementation] = version;
        } catch {
            implementationVersion[_implementation] = 1;
        }
        
        emit ImplementationUpgraded(address(0), _implementation, implementationVersion[_implementation]);
        
        // Initialize the implementation
        (bool success,) = _implementation.delegatecall(
            abi.encodeWithSelector(ISubscriptionLogic.initialize.selector)
        );
        require(success, "UpgradeHub: initialization failed");
    }
    
    // ==================== UPGRADE FUNCTIONS ====================
    
    /**
     * @dev Upgrade to a new implementation contract
     */
    function upgrade(address newImplementation) external onlyAdmin {
        require(newImplementation != address(0), "UpgradeHub: invalid implementation");
        require(newImplementation != implementation, "UpgradeHub: same implementation");
        require(
            newImplementation.code.length > 0,
            "UpgradeHub: implementation is not a contract"
        );
        
        // Verify the new implementation implements the interface
        try ISubscriptionLogic(newImplementation).getVersion() returns (uint256 version) {
            // Check version is newer
            uint256 currentVersion = implementationVersion[implementation];
            require(version > currentVersion, "UpgradeHub: version must be newer");
            
            address oldImplementation = implementation;
            implementation = newImplementation;
            approvedImplementations[newImplementation] = true;
            implementationHistory.push(newImplementation);
            implementationVersion[newImplementation] = version;
            
            // Initialize new implementation if needed
            (bool success,) = newImplementation.delegatecall(
                abi.encodeWithSelector(ISubscriptionLogic.initialize.selector)
            );
            require(success, "UpgradeHub: new implementation initialization failed");
            
            emit ImplementationUpgraded(oldImplementation, newImplementation, version);
            
        } catch {
            revert("UpgradeHub: invalid implementation interface");
        }
    }
    
    /**
     * @dev Propose admin transfer
     */
    function proposeAdminTransfer(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "UpgradeHub: invalid admin address");
        require(newAdmin != admin, "UpgradeHub: same admin");
        
        pendingAdmin = newAdmin;
    }
    
    /**
     * @dev Accept admin transfer
     */
    function acceptAdminTransfer() external {
        require(msg.sender == pendingAdmin, "UpgradeHub: caller is not pending admin");
        
        address oldAdmin = admin;
        admin = pendingAdmin;
        pendingAdmin = address(0);
        
        emit AdminChanged(oldAdmin, admin);
    }
    
    /**
     * @dev Emergency pause
     */
    function pause() external onlyAdmin {
        paused = true;
        emit ContractPaused(admin);
    }
    
    /**
     * @dev Unpause contract
     */
    function unpause() external onlyAdmin {
        paused = false;
        emit ContractUnpaused(admin);
    }
    
    // ==================== DELEGATECALL WRAPPER ====================
    
    /**
     * @dev Internal function to delegate calls to implementation
     */
    function _delegate() internal validImplementation {
        address impl = implementation;
        
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code
            calldatacopy(0, 0, calldatasize())
            
            // Call the implementation
            // out and outsize are 0 because we don't know the size yet
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            
            // Copy the returned data
            returndatacopy(0, 0, returndatasize())
            
            switch result
            // delegatecall returns 0 on error
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    // ==================== FALLBACK AND RECEIVE ====================
    
    /**
     * @dev Fallback function that delegates calls to the implementation contract
     */
    fallback() external payable whenNotPaused {
        _delegate();
    }
    
    /**
     * @dev Receive function for handling ETH transfers
     */
    receive() external payable whenNotPaused {
        _delegate();
    }
    
    // ==================== VIEW FUNCTIONS ====================
    
    /**
     * @dev Get current implementation info
     */
    function getImplementationInfo() external view returns (
        address currentImplementation,
        uint256 version,
        string memory description
    ) {
        currentImplementation = implementation;
        version = implementationVersion[implementation];
        
        try ISubscriptionLogic(implementation).getDescription() returns (string memory desc) {
            description = desc;
        } catch {
            description = "No description available";
        }
    }
    
    /**
     * @dev Get implementation history
     */
    function getImplementationHistory() external view returns (address[] memory) {
        return implementationHistory;
    }
    
    /**
     * @dev Get contract state
     */
    function getContractState() external view returns (
        address currentAdmin,
        address currentImplementation,
        bool isPaused,
        uint256 plansCount,
        uint256 subscriptionsCount,
        uint256 contractRevenue
    ) {
        return (admin, implementation, paused, totalPlans, totalSubscriptions, totalRevenue);
    }
    
    /**
     * @dev Check if implementation is approved
     */
    function isImplementationApproved(address impl) external view returns (bool) {
        return approvedImplementations[impl];
    }
    
    // ==================== EMERGENCY FUNCTIONS ====================
    
    /**
     * @dev Emergency withdrawal (admin only)
     */
    function emergencyWithdraw(uint256 amount) external onlyAdmin {
        require(amount <= address(this).balance, "UpgradeHub: insufficient balance");
        payable(admin).transfer(amount);
    }
    
    /**
     * @dev Rollback to previous implementation (emergency)
     */
    function emergencyRollback() external onlyAdmin {
        require(implementationHistory.length > 1, "UpgradeHub: no previous implementation");
        
        address currentImpl = implementation;
        address previousImpl = implementationHistory[implementationHistory.length - 2];
        
        implementation = previousImpl;
        
        emit ImplementationUpgraded(
            currentImpl,
            previousImpl,
            implementationVersion[previousImpl]
        );
    }
}
