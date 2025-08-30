// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";
import "./BasicDepositBox.sol";
import "./PremiumDepositBox.sol";
import "./TimeLockedDepositBox.sol";

contract VaultManager {
    struct BoxInfo {
        address boxAddress;
        string boxType;
        address owner;
    }

    mapping(address => BoxInfo[]) private userBoxes;
    mapping(address => bool) private registeredBoxes;
    
    event BoxCreated(address indexed owner, address indexed boxAddress, string boxType);
    event BoxTransferred(address indexed from, address indexed to, address indexed boxAddress);

    function createBasicBox() external returns (address) {
        BasicDepositBox newBox = new BasicDepositBox();
        _registerBox(address(newBox), "Basic", msg.sender);
        return address(newBox);
    }

    function createPremiumBox() external returns (address) {
        PremiumDepositBox newBox = new PremiumDepositBox();
        _registerBox(address(newBox), "Premium", msg.sender);
        return address(newBox);
    }

    function createTimeLockedBox() external returns (address) {
        TimeLockedDepositBox newBox = new TimeLockedDepositBox();
        _registerBox(address(newBox), "TimeLocked", msg.sender);
        return address(newBox);
    }

    function _registerBox(address boxAddress, string memory boxType, address owner) internal {
        require(!registeredBoxes[boxAddress], "Box already registered");
        
        BoxInfo memory newBox = BoxInfo({
            boxAddress: boxAddress,
            boxType: boxType,
            owner: owner
        });
        
        userBoxes[owner].push(newBox);
        registeredBoxes[boxAddress] = true;
        
        emit BoxCreated(owner, boxAddress, boxType);
    }

    function getUserBoxes(address user) external view returns (BoxInfo[] memory) {
        return userBoxes[user];
    }

    function getBoxInfo(address boxAddress) external view returns (BoxInfo memory) {
        require(registeredBoxes[boxAddress], "Box not registered");
        
        IDepositBox box = IDepositBox(boxAddress);
        address owner = box.getOwner();
        string memory boxType = box.getBoxType();
        
        return BoxInfo({
            boxAddress: boxAddress,
            boxType: boxType,
            owner: owner
        });
    }

    function transferBox(address boxAddress, address newOwner) external {
        require(registeredBoxes[boxAddress], "Box not registered");
        
        IDepositBox box = IDepositBox(boxAddress);
        address currentOwner = box.getOwner();
        
        require(msg.sender == currentOwner, "Only owner can transfer box");
        require(newOwner != address(0), "New owner cannot be zero address");
        
        // Update the box ownership
        box.transferOwnership(newOwner);
        
        // Update our records
        BoxInfo[] storage boxes = userBoxes[currentOwner];
        for (uint i = 0; i < boxes.length; i++) {
            if (boxes[i].boxAddress == boxAddress) {
                boxes[i].owner = newOwner;
                break;
            }
        }
        
        userBoxes[newOwner].push(BoxInfo({
            boxAddress: boxAddress,
            boxType: box.getBoxType(),
            owner: newOwner
        }));
        
        emit BoxTransferred(currentOwner, newOwner, boxAddress);
    }
} 