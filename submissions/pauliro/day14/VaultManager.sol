// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDepositBox} from "./IDepositBox.sol";
import {BasicDepositBox} from "./BasicDepositBox.sol";
import {PremiumDepositBox} from "./PremiumDepositBox.sol";
import {TimeLockedDepositBox} from "./TimeLockedDepositBox.sol";

contract VaultManager {
    mapping(address => address[]) private userDepositBox;
    mapping(address => string) private boxNames;

    event BoxCreated(address indexed owner, address indexed boxAddress, string boxType);
    event BoxNamed(address indexed boxAddress, string name);

    function createBasicBox() external returns (address) {
        BasicDepositBox box = new BasicDepositBox();
        userDepositBox[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Basic");
        return address(box);
    }

    function createPremiumBox() external returns (address) {
        PremiumDepositBox box = new PremiumDepositBox();
        userDepositBox[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Premium");
        return address(box);
    }

    function nameBox(address _boxAddress, string calldata _name) external {
        IDepositBox box = IDepositBox(_boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        boxNames[_boxAddress] = _name;
        emit BoxNamed(_boxAddress, _name);
    }

    function createTimeLockedBox(uint256 _lockDuration) external returns (address) {
        TimeLockedDepositBox box = new TimeLockedDepositBox(_lockDuration);
        userDepositBox[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "TimeLocked");
        return address(box);
    }    

    function transferBoxOwnership(address _boxAddress, address _newOwner) external {
        IDepositBox box = IDepositBox(_boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        box.transferOwnership(_newOwner);

        address[] storage boxes = userDepositBox[msg.sender];
        for (uint i = 0; i < boxes.length; i++) {
            if (boxes[i] == _boxAddress) {
                boxes[i] = boxes[boxes.length - 1];
                boxes.pop();
                break;
            }
        }
        userDepositBox[_newOwner].push(_boxAddress);
    }

    function storeSecret(address _boxAddress, string calldata _secret) external {
        IDepositBox box = IDepositBox(_boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        box.storeSecret(_secret);
    }

    

    function getUserBoxes(address _user) external view returns (address[] memory) {
        return userDepositBox[_user];
    }

    function getBoxName(address _boxAddress) external view returns (string memory) {
        return boxNames[_boxAddress];
    }

    function getBoxInfo(address _boxAddress) external view returns (string memory boxType, address owner,
        uint256 depositTime,string memory name) {
        IDepositBox box = IDepositBox(_boxAddress);
        return (box.getBoxType(), box.getOwner(), box.getDepositTime(), boxNames[_boxAddress]);
    }
}

