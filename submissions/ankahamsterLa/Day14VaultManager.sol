//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

import "./Day14IDepositBox.sol";
import "./Day14BasicDepositBox.sol";
import "./Day14PremiumDepositBox.sol";
import "./Day14TimeLockedDepositBox.sol";

// This contract acts like the control center for users to create, name, manage and interact with deposit boxes.
// vault system backend: let users create different types of boxes(basic,premium,time-locked),keep track of which user owns which boxes, enforces ownership fules and provides helper functions for naming and retrieving box info.
contract VaultManager{
    // Maps a user's address to all the deposit boxes they own
    mapping(address=>address[]) private userDepositBoxes;
    // lets users assign custom names to each of their boxes.
    mapping(address=>string) private boxNames;

    event BoxCreated(address indexed owner,address indexed boxAddress,string boxType);
    event BoxNamed(address indexed boxAddress, string name);

    function createBasicBox() external returns (address){
        // This line deploys a new "BasicDepositBox" contract and stores its address in the variable "box".
        BasicDepositBox box=new BasicDepositBox();
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender,address(box),"Basic");
        return address(box);
    }

    function createPremiumBox() external returns(address){
        // It is a special kind of deposit box that support extra data through the "setMetadata()" function.
        PremiumDepositBox box=new PremiumDepositBox();
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender,address(box),"Premium");
        return address(box);
    }

    function createTimeLockedBox(uint256 lockDuration) external returns (address){
        // "lockDuration" is the variable which is declared in the constructor of the "TimeLockedDepositBox" contract.
        TimeLockedDepositBox box=new TimeLockedDepositBox(lockDuration);
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender,address(box),"Time Locked");
        return address(box);
    }

    function nameBox(address boxAddress,string memory name) external{
        // Create an Interface Instance Using a Contract Address
        // Cast the generic address into the interface.
        IDepositBox box=IDepositBox(boxAddress);
        require(box.getOwner()==msg.sender,"Not the box owner");
        boxNames[boxAddress]=name;
        emit BoxNamed(boxAddress,name);
    }

    function storeSecret(address boxAddress, string calldata secret) external{
        IDepositBox box=IDepositBox(boxAddress);
        require(box.getOwner()==msg.sender,"Not the box owner");
        box.storeSecret(secret);
    }


    function transferBoxOwnership(address boxAddress,address newOwner) external{
        IDepositBox box= IDepositBox(boxAddress);
        require(box.getOwner()==msg.sender,"Not the box owner");
        box.transferOwnership(newOwner);
        address[] storage boxes=userDepositBoxes[msg.sender];
        // Remove the box from the sender's list.
        // Loop through the sender's list to find the one that's being transferred. Once we find it: swap it with the last item in the array and then call ".pop()" to remove the last item.
        for (uint i=0;i<boxes.length;i++) {
            boxes[i]=boxes[boxes.length-1];
            boxes.pop();
            break;
        }
 
        userDepositBoxes[newOwner].push(boxAddress);
    }

    function getUserBoxes(address user) external view returns(address[] memory){
        return userDepositBoxes[user];
    }

    function getBoxName(address boxAddress) external view returns(string memory){
        return boxNames[boxAddress];
    }

    function getBoxInfo(address boxAddress) external view returns(string memory boxType,address owner,uint256 depositTime,string memory name){
        IDepositBox box=IDepositBox(boxAddress);
        return(box.getBoxType(),box.getOwner(),box.getDepositTime(),boxNames[boxAddress]);
    }

    
}