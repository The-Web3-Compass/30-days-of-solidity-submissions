// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IDepositBox} from "./IDepositBox.sol";
import {BasicDepositBox} from "./BasicDepositBox.sol";
import {PremiumDepositBox} from "./PremiumDepositBox.sol";
import {TimeLockedDepositBox} from "./TimeLockedDepositBox.sol";


contract VaultManger {
    error VaultManager_InvalidLockDuration();
    error VaultManager_BoxNotFound();
    error VaultManager_NotBoxOwner();
    error VaultManager_NoBoxType();
    error VaultManager_ZeroAddress();

    struct BoxRegistry {
        IDepositBox boxContract;
        string boxType;
        address currentOwner;
        address originalOwner;
        uint256 createdAt;
        // uint256 lastUpdate; 
        bool isActive;
    }

    mapping (uint256 => BoxRegistry) public boxes;
    mapping(address => uint256[]) userBoxes;
    mapping(string => uint256) public boxTypeCount;

    uint256 public boxCount;
    uint256 private boxesDeactivated;

    // Events
    event BoxCreated(
        uint256 indexed boxId, 
        string indexed boxType, 
        address indexed owner, 
        address boxContract
    );
    
    event BoxOwnershipTransferred(
        uint256 indexed boxId, 
        address indexed oldOwner, 
        address indexed newOwner,
        uint256 updatedTime
    );
    
    event BoxInteraction(
        uint256 indexed boxId, 
        address indexed user, 
        string action,
        uint256 updatedTime
    );
    
    event BoxDeactivated(uint256 indexed boxId, address indexed owner, uint256 updatedTime);

    // ======================
    // Box Creation
    // ======================

    function createBasicBox() external returns(uint256) {
        BasicDepositBox newBox = new BasicDepositBox();
        return _registerBox(IDepositBox(newBox), "Basic", msg.sender);
    }
    
    function createPremiumBox() external returns(uint256) {
        PremiumDepositBox newBox = new PremiumDepositBox();
        return _registerBox(IDepositBox(newBox), "Premium", msg.sender);
    }
    function createTimeLockedBox(uint256 lockDuration) external returns(uint256) {
        if (lockDuration == 0) revert VaultManager_InvalidLockDuration();
        TimeLockedDepositBox newBox = new TimeLockedDepositBox(lockDuration);
        return _registerBox(IDepositBox(newBox), "TimeLocked", msg.sender);
    }

    // ======================
    // Box interaction func
    // ======================

    function storeSecretInBox(uint256 boxId, string calldata secret) external {
        _validateBoxAccess(boxId, msg.sender);
        boxes[boxId].boxContract.storeSecret(secret);
        emit BoxInteraction(boxId, msg.sender, "SECRET_STORED", block.timestamp);
    }
    function updateSecretInBox(uint256 boxId, string calldata secret) external {
        _validateBoxAccess(boxId, msg.sender);
        boxes[boxId].boxContract.updateSecret(secret);
        emit BoxInteraction(boxId, msg.sender, "SECRET_UPDATED", block.timestamp);
    }

    function transferOwnerShip(uint256 boxId, address newOwner) external {
        if (newOwner == address(0)) revert VaultManager_ZeroAddress();

        _validateBoxAccess(boxId, msg.sender);
        if (msg.sender == newOwner) return; // same address so no need to do anything

        address oldOwner = boxes[boxId].currentOwner;             
        boxes[boxId].boxContract.transferOwnership(newOwner);

        _updateOwnershipRegistry(boxId, oldOwner, newOwner);
        emit BoxOwnershipTransferred(boxId, oldOwner, newOwner, block.timestamp);
        emit BoxInteraction(boxId, msg.sender, "OWNERSHIP_TRANSFERED", block.timestamp);
    }

    function deactivateBox(uint256 boxId) external {
        _validateBoxAccess(boxId, msg.sender);
        
        boxes[boxId].isActive = false;
        boxesDeactivated++;
        
        emit BoxDeactivated(boxId, msg.sender, block.timestamp);
    }
    
    // ======================
    // view functions
    // ======================

    function getBoxInfo(uint256 boxId) external view returns(BoxRegistry memory) {
        _validateBoxExists(boxId);
        return boxes[boxId];
    }

    function getTotalActiveBoxes() public view returns (uint256) {
        return boxCount - boxesDeactivated;
    }

    function getUserBoxes(address user) external view returns (uint256[] memory) {
        return userBoxes[user];
    }

    function getUserActiveBoxes(address user) external view returns (uint256[] memory) {
        uint256[] memory allBoxes = userBoxes[user];
        uint256 activeCount = 0;
        
        // Count active boxes first
        for (uint256 i = 0; i < allBoxes.length; i++) {
            if (boxes[allBoxes[i]].isActive) {
                activeCount++;
            }
        }
        
        // Create array with correct size
        uint256[] memory activeBoxes = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allBoxes.length; i++) {
            if (boxes[allBoxes[i]].isActive) {
                activeBoxes[index] = allBoxes[i];
                index++;
            }
        }
        
        return activeBoxes;
    }

    function getBoxesByType(string calldata boxType) external view returns (uint256[] memory) {
        uint256 count = boxTypeCount[boxType];
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        bytes32 boxTypeHash = keccak256(abi.encodePacked(boxType));

        for (uint256 i = 0; i < boxCount; i++) {
            if (boxes[i].isActive && _isEqualWithHash(boxes[i].boxType, boxTypeHash)) {
                result[index] = i;
                index++;
            }
        }
        return result;
    }
    
    
    // ======================
    // helper functions
    // ======================

    function _registerBox(
        IDepositBox boxContract,
        string memory boxType,
        address owner
    ) internal returns (uint256) {
        uint256 boxId = boxCount++;

        boxes[boxId] = BoxRegistry({
            boxContract: boxContract, 
            boxType: boxType,
            currentOwner: owner,
            originalOwner: owner,
            createdAt: block.timestamp,
            // lastUpdate: block.timestamp,
            isActive: true
        });

        userBoxes[owner].push(boxId);
        boxTypeCount[boxType]++;
        emit BoxCreated(boxId, boxType, owner, address(boxContract));
        return boxId;
    }

    function _validateBoxAccess(uint256 boxId, address user) internal view {
        _validateBoxExists(boxId);

        if (boxes[boxId].currentOwner != user) revert VaultManager_NotBoxOwner();
        if (!boxes[boxId].isActive) revert VaultManager_BoxNotFound();
    }

    function _validateBoxExists(uint256 boxId) internal view {
        if (!_ifBoxExists(boxId)) revert VaultManager_BoxNotFound();
    }

    function _ifBoxExists(uint256 boxId) internal view returns (bool) {
        return boxId < boxCount && address(boxes[boxId].boxContract) != address(0);
    }

    function _updateOwnershipRegistry(uint256 boxId, address oldOwner, address newOwner) internal {
        
        boxes[boxId].currentOwner = newOwner;

        // Remove from old onwer's list
        uint256[] storage oldOwnerBoxes = userBoxes[oldOwner];
        for (uint256 i= 0; i < oldOwnerBoxes.length; i++) {
            if (oldOwnerBoxes[i] == boxId) {
                oldOwnerBoxes[i] = oldOwnerBoxes[oldOwnerBoxes.length - 1]; 
                oldOwnerBoxes.pop();
                break;
            }
        }
        userBoxes[newOwner].push(boxId);
    }

    function _isEqualWithHash(string memory a, bytes32 boxTypeHash) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == boxTypeHash;
    }

}