//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day14-IDepositBox.sol";
import "./day14-BasicDepositBox.sol";
import "./day14-PremiumDepositBox.sol";
import "./day14-TimeLockedDepositBox.sol";

contract VaultManager {
    mapping(address => address[]) private userDepositBoxes;
    mapping(address => string) private boxNames;

    event BoxCreated(address indexed boxOwner, address indexed boxAddress, string boxType);
    event BoxNamed(address indexed boxAddress, string boxName);

    function createBasicBox() external returns(address) {
        BasicDepositBox box = new BasicDepositBox();
        userDepositBoxes[msg.sender].push(address(box));
        
        emit BoxCreated(msg.sender, address(box), "Basic");
        return address(box);
    }

    function createPremiunBox() external returns(address) {
        PremiumDepositBox box = new PremiumDepositBox();
        userDepositBoxes[msg.sender].push(address(box));

        emit BoxCreated(msg.sender, address(box), "Premium");
        return address(box);
    }

    function createTimeLockedBox(uint256 timeDuration) external returns(address) {
        TimeLockedDepositBox box = new TimeLockedDepositBox(timeDuration);
        userDepositBoxes[msg.sender].push(address(box));

        emit BoxCreated(msg.sender, address(box), "TimeLocked");
        return address(box);
    }

    function storeSecret(address _boxAddress, string calldata _secret) external {
        IDepositBox box = IDepositBox(_boxAddress);
        // The owner permission has already been checked in BasicDepositBox, 
        // so is it okay not to check it here?
        require(msg.sender == box.getOwner(), "Only the owner can perform this action");
        box.storeSecret(_secret);
    }

    function nameBox(address _boxAddress, string calldata _name) external {
        IDepositBox box = IDepositBox(_boxAddress);
        require(msg.sender == box.getOwner(), "Only the owner can perform this action");

        boxNames[_boxAddress] = _name;
        emit BoxNamed(_boxAddress, _name);
    }

    function transferOwner(address _boxAddress, address _newOwner) external {
        IDepositBox box = IDepositBox(_boxAddress);
        // The owner permission has already been checked in BasicDepositBox, 
        // so is it okay not to check it here?
        require(msg.sender == box.getOwner(), "Only the owner can perform this action");

        box.transferOwner(_newOwner);

        address[] storage boxes = userDepositBoxes[msg.sender];
        for(uint i = 0; i < boxes.length; i++) {
            if (boxes[i] == _boxAddress) {
                boxes[i] = boxes[boxes.length - 1];
                boxes.pop();
                break;
            }
        }
        userDepositBoxes[_newOwner].push(_boxAddress);
    }

    function getSecret(address _boxAddress) external view returns(string memory) {
        IDepositBox box = IDepositBox(_boxAddress);
        // The owner permission has already been checked in BasicDepositBox, 
        // so is it okay not to check it here?
        require(msg.sender == box.getOwner(), "Only the owner can perform this action");
        return box.getSecret();
    }

    function getBoxOwner(address _boxAddress) external view returns(address) {
        IDepositBox box = IDepositBox(_boxAddress);
        return box.getOwner();
    }

    function getUserBoxex(address _userAddress) external view returns(address[] memory) {
        return userDepositBoxes[_userAddress];
    }

    function getBoxName(address _boxAddress) external view returns(string memory) {
        return boxNames[_boxAddress];
    }

    function getBoxInfo(address _boxAddress) external view returns(
        string memory boxType,
        uint256 boxCreatedTime,
        address owner,
        string memory name
    ) {
        IDepositBox box = IDepositBox(_boxAddress);
        return (box.getBoxType(),
                box.getBoxCreatedTime(),
                box.getOwner(),
                boxNames[_boxAddress]
        );
    }

}