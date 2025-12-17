// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Day14 IDepositBox.sol";
import "./Day14 BasicDepositBox.sol";
import "./Day14 PremiumDepositBox.sol";
import "./Day14 TimeLockedDepositBox.sol";


contract VaultManager {

    // --- State Variables ---
    mapping(address => address[]) public userBoxes; // 用户 -> 他的保险箱地址列表
    mapping(address => address) public boxToOwner; // 保险箱地址 -> 其所有者地址
    mapping(address => string) public boxNames; // 保险箱地址 -> 用户定义的名称

    // --- Events ---
    event BoxCreated(address indexed owner, address indexed boxAddress, string boxType);
    event BoxRenamed(address indexed boxAddress, string newName);
    event BoxOwnershipTransferred(address indexed boxAddress, address indexed from, address indexed to);
    
    // --- Box Creation ---
    function createBasicBox() external {
        _createBox("Basic", msg.sender, 0);
    }

    function createPremiumBox() external {
        _createBox("Premium", msg.sender, 0);
    }
    
    function createTimeLockedBox(uint256 lockDurationSeconds) external {
        _createBox("TimeLocked", msg.sender, lockDurationSeconds);
    }
    
    function _createBox(string memory _boxType, address _owner, uint256 _duration) private {
        address newBoxAddress;
        if (keccak256(bytes(_boxType)) == keccak256(bytes("Basic"))) {
            newBoxAddress = address(new BasicDepositBox(_owner));
        } else if (keccak256(bytes(_boxType)) == keccak256(bytes("Premium"))) {
            newBoxAddress = address(new PremiumDepositBox(_owner));
        } else if (keccak256(bytes(_boxType)) == keccak256(bytes("TimeLocked"))) {
            newBoxAddress = address(new TimeLockedDepositBox(_owner, _duration));
        } else {
            revert("Invalid box type");
        }
        
        userBoxes[_owner].push(newBoxAddress);
        boxToOwner[newBoxAddress] = _owner;
        
        emit BoxCreated(_owner, newBoxAddress, _boxType);
    }

    // --- Box Management ---
    function renameBox(address _boxAddress, string memory _newName) external {
        require(boxToOwner[_boxAddress] == msg.sender, "Only owner can rename the box");
        boxNames[_boxAddress] = _newName;
        emit BoxRenamed(_boxAddress, _newName);
    }

    function transferBox(address _boxAddress, address _newOwner) external {
        require(boxToOwner[_boxAddress] == msg.sender, "Only owner can transfer the box");
        
        address currentOwner = msg.sender;
        
        // 1. 调用保险箱合约自身的功能来转移所有权
        IDepositBox(_boxAddress).transferOwnership(_newOwner);
        
        // 2. 更新管理器内部的状态
        _removeBoxFromUser(currentOwner, _boxAddress);
        userBoxes[_newOwner].push(_boxAddress);
        boxToOwner[_boxAddress] = _newOwner;
        
        emit BoxOwnershipTransferred(_boxAddress, currentOwner, _newOwner);
    }
    
    // --- View Functions ---
    function getBoxesForUser(address _user) external view returns (address[] memory) {
        return userBoxes[_user];
    }
    
    // --- Internal Helper ---
    function _removeBoxFromUser(address _user, address _boxAddress) private {
        address[] storage boxes = userBoxes[_user];
        for (uint i = 0; i < boxes.length; i++) {
            if (boxes[i] == _boxAddress) {
                // 将最后一个元素移到当前位置，然后弹出最后一个元素
                boxes[i] = boxes[boxes.length - 1];
                boxes.pop();
                break;
            }
        }
    }
}
