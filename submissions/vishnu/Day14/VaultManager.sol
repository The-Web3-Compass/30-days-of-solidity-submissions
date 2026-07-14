// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";

contract VaultManager {
    address public owner;
    

    mapping(address => bool) public registeredBoxes;
    mapping(address => address[]) public userBoxes; 
    mapping(string => address[]) public boxesByType; 
    
    address[] public allBoxes;
    

    mapping(string => uint256) public creationFees;

    event BoxRegistered(address indexed boxAddress, string boxType, address indexed owner);
    event BoxInteraction(address indexed user, address indexed boxAddress, string action);
    event FeesUpdated(string boxType, uint256 newFee);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "VaultManager: caller is not the owner");
        _;
    }
    
    modifier onlyRegisteredBox(address boxAddress) {
        require(registeredBoxes[boxAddress], "VaultManager: box not registered");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        
        creationFees["Basic"] = 0.01 ether;
        creationFees["Premium"] = 0.05 ether;
        creationFees["TimeLock"] = 0.03 ether;
    }
    
    
    function registerBox(address boxAddress) external {
        require(boxAddress != address(0), "VaultManager: invalid box address");
        require(!registeredBoxes[boxAddress], "VaultManager: box already registered");
        
        IDepositBox box = IDepositBox(boxAddress);
        try box.getBoxInfo() returns (
            string memory boxType, 
            IDepositBox.BoxStatus status, 
            uint256 balance, 
            address boxOwner, 
            uint256 creationTime
        ) {
            registeredBoxes[boxAddress] = true;
            userBoxes[boxOwner].push(boxAddress);
            boxesByType[boxType].push(boxAddress);
            allBoxes.push(boxAddress);
            
            emit BoxRegistered(boxAddress, boxType, boxOwner);
        } catch {
            revert("VaultManager: invalid deposit box contract");
        }
    }

    
    function unregisterBox(address boxAddress) external onlyOwner {
        require(registeredBoxes[boxAddress], "VaultManager: box not registered");
        
        registeredBoxes[boxAddress] = false;

        for (uint256 i = 0; i < allBoxes.length; i++) {
            if (allBoxes[i] == boxAddress) {
                allBoxes[i] = allBoxes[allBoxes.length - 1];
                allBoxes.pop();
                break;
            }
        }
    }
    
    function depositToBox(address boxAddress) external payable onlyRegisteredBox(boxAddress) {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.canDeposit(), "VaultManager: box cannot accept deposits");
        
        box.deposit{value: msg.value}();
        
        emit BoxInteraction(msg.sender, boxAddress, "deposit");
    }
    
    function withdrawFromBox(address boxAddress, uint256 amount) external onlyRegisteredBox(boxAddress) {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.owner() == msg.sender, "VaultManager: not box owner");
        require(box.canWithdraw(), "VaultManager: cannot withdraw from box");
        
        box.withdraw(amount);
        
        emit BoxInteraction(msg.sender, boxAddress, "withdraw");
    }
    
    function withdrawAllFromBox(address boxAddress) external onlyRegisteredBox(boxAddress) {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.owner() == msg.sender, "VaultManager: not box owner");
        require(box.canWithdraw(), "VaultManager: cannot withdraw from box");
        
        box.withdrawAll();
        
        emit BoxInteraction(msg.sender, boxAddress, "withdrawAll");
    }
    
    function storeSecretInBox(address boxAddress, string memory secretHash) external onlyRegisteredBox(boxAddress) {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.owner() == msg.sender, "VaultManager: not box owner");
        
        box.storeSecret(secretHash);
        
        emit BoxInteraction(msg.sender, boxAddress, "storeSecret");
    }
    
    function transferBoxOwnership(address boxAddress, address newOwner) external onlyRegisteredBox(boxAddress) {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.owner() == msg.sender, "VaultManager: not box owner");
        require(newOwner != address(0), "VaultManager: new owner cannot be zero address");

        address[] storage senderBoxes = userBoxes[msg.sender];
        for (uint256 i = 0; i < senderBoxes.length; i++) {
            if (senderBoxes[i] == boxAddress) {
                senderBoxes[i] = senderBoxes[senderBoxes.length - 1];
                senderBoxes.pop();
                break;
            }
        }
        
        userBoxes[newOwner].push(boxAddress);

        box.transferOwnership(newOwner);
        
        emit BoxInteraction(msg.sender, boxAddress, "transferOwnership");
    }

    
    function batchDeposit(address[] memory boxAddresses, uint256[] memory amounts) external payable {
        require(boxAddresses.length == amounts.length, "VaultManager: arrays length mismatch");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(msg.value >= totalAmount, "VaultManager: insufficient ETH sent");
        
        for (uint256 i = 0; i < boxAddresses.length; i++) {
            require(registeredBoxes[boxAddresses[i]], "VaultManager: box not registered");
            
            IDepositBox box = IDepositBox(boxAddresses[i]);
            require(box.canDeposit(), "VaultManager: box cannot accept deposits");
            
            box.deposit{value: amounts[i]}();
            emit BoxInteraction(msg.sender, boxAddresses[i], "batchDeposit");
        }

        if (msg.value > totalAmount) {
            payable(msg.sender).transfer(msg.value - totalAmount);
        }
    }
    
    function batchWithdrawAll(address[] memory boxAddresses) external {
        for (uint256 i = 0; i < boxAddresses.length; i++) {
            require(registeredBoxes[boxAddresses[i]], "VaultManager: box not registered");
            
            IDepositBox box = IDepositBox(boxAddresses[i]);
            require(box.owner() == msg.sender, "VaultManager: not box owner");
            
            if (box.canWithdraw()) {
                box.withdrawAll();
                emit BoxInteraction(msg.sender, boxAddresses[i], "batchWithdrawAll");
            }
        }
    }
    
    function getUserBoxes(address user) external view returns (address[] memory) {
        return userBoxes[user];
    }
    
    function getBoxesByType(string memory boxType) external view returns (address[] memory) {
        return boxesByType[boxType];
    }
    
    function getAllBoxes() external view returns (address[] memory) {
        return allBoxes;
    }
    
    function getBoxInfo(address boxAddress) external view onlyRegisteredBox(boxAddress) returns (
        string memory boxType,
        IDepositBox.BoxStatus status,
        uint256 balance,
        address currentOwner,
        uint256 creationTime
    ) {
        IDepositBox box = IDepositBox(boxAddress);
        return box.getBoxInfo();
    }
    
    function getUserBoxSummary(address user) external view returns (
        uint256 totalBoxes,
        uint256 totalBalance,
        address[] memory boxAddresses,
        string[] memory boxTypes
    ) {
        address[] memory boxes = userBoxes[user];
        totalBoxes = boxes.length;
        boxAddresses = boxes;
        boxTypes = new string[](boxes.length);
        
        for (uint256 i = 0; i < boxes.length; i++) {
            IDepositBox box = IDepositBox(boxes[i]);
            (, , uint256 balance, , ) = box.getBoxInfo();
            totalBalance += balance;
            
            (string memory boxType, , , , ) = box.getBoxInfo();
            boxTypes[i] = boxType;
        }
    }

    
    function setCreationFee(string memory boxType, uint256 fee) external onlyOwner {
        creationFees[boxType] = fee;
        emit FeesUpdated(boxType, fee);
    }
    
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "VaultManager: no fees to withdraw");
        
        payable(owner).transfer(balance);
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "VaultManager: new owner cannot be zero address");
        
        address previousOwner = owner;
        owner = newOwner;
        
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    
    function emergencyPause(address boxAddress) external onlyOwner onlyRegisteredBox(boxAddress) {
        unregisterBox(boxAddress);
    }
}
