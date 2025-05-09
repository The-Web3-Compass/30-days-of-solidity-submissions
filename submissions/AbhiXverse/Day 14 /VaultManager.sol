// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

import "./IDepositBox.sol";
import "./BasicDepositBox.sol";
import "./PremiumDepositBox.sol";
import "./TimeLockedDepositBox.sol";


contract VaultManager{

    // Stores all deposit box addresses created by a user 
    mapping (address => address[]) private userDepositBoxes;

    // stores custom names given to boxes 
    mapping (address => string) private boxNames;

    // event emit when a box is created 
    event BoxCreated(address indexed owner , address indexed boxAddress, string boxType);

    // event emitted when a box is named 
    event BoxNamed(address indexed boxAddress, string name);
 
    // function to create a basic box
    function createBasicBox() external returns (address) {
        BasicDepositBox box = new BasicDepositBox(msg.sender);                     // create box 
        userDepositBoxes[msg.sender].push(address(box));                 // record it under a sender
        emit BoxCreated(msg.sender, address(box), "Basic");             
        return address(box);
    }

    // function to create a premium box
    function createPremiumBox() external returns (address) {
        PremiumDepositBox box = new PremiumDepositBox(msg.sender);
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Premium");
        return address(box);
    }

    // function to create a timelocked box
    function createTimelockedBox(uint256 _lockDuration) external returns (address) {
        TimeLockedDepositBox box = new TimeLockedDepositBox(msg.sender, _lockDuration);
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Timeloceked");
        return address(box);
    }

    // function to assign a name to a box
    function nameBox(address boxAddress, string memory name) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        boxNames[boxAddress] = name;
        emit BoxNamed(boxAddress, name);
    } 

    // function to store a secret in a box 
    function storeSecret(address boxAddress, string calldata secret) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        box.storeSecret(secret);
    }

    function viewSecret(address boxAddress) external view returns(string memory) {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        return box.getSecret();
    }

    // function to transfer the ownership of a box to someone else 
    function transferOwnership(address boxAddress, address newOwner) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(msg.sender == box.getOwner(), "Not the box owner");
        box.transferOwnership(newOwner);
        address[] storage boxes = userDepositBoxes[msg.sender];
        for(uint i = 0; i<boxes.length; i++) {
            if (boxes[i] == boxAddress) {                          // only modify if it's the correct box 
            boxes[i] = boxes[boxes.length - 1];                    // replace with the last 
            boxes.pop();                                           // remore the last 
            break;
            }}
         userDepositBoxes[newOwner].push(boxAddress);             // add the box under the new owner
    }

    // function to view all the boxes of a user 
    function getUserBoxes(address user) external view returns (address[] memory) {
        return userDepositBoxes[user];
    }

    // get the custom name of a box 
    function getBoxName(address boxAddress) external view returns(string memory) {
        return boxNames[boxAddress];
    }
 
    // get info about a box 
    function getBoxInfo(address BoxAddress) external view returns (
        string memory boxType,
        address owner,
        uint256 depositTime,
        string memory name
        ) {
            IDepositBox box = IDepositBox(BoxAddress);
            return (
                box.getBoxType(),
                box.getOwner(),
                box.getDepositTime(),
                boxNames[BoxAddress]
            );
        }
}