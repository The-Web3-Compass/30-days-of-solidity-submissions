// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IDepositBox.sol";
import "./BasicDepositBox.sol";
import "./PremiumDepositBox.sol";
import "./TimeLockedDepositBox.sol";

contract VaultManager {
    mapping(address => address[]) private _userDepositBoxes;
    mapping(address => string) private _boxNames;

    event BoxCreated(address indexed owner, address indexed boxAddress, string boxType);
    event BoxNamed(address indexed boxAddress, string name);

    function createBasicBox() public returns (address) {
        BasicDepositBox box = new BasicDepositBox();
        _userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Basic");
        return address(box);
    }

    function createPremiumBox() public returns (address) {
        PremiumDepositBox box = new PremiumDepositBox();
        _userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Premium");
        return address(box);
    }

    function createTimeLockedBox(uint256 lockDuration) public returns (address) {
        require(lockDuration > 0, "Lock duration must be > 0");
        require(lockDuration <= 365 days, "Max lock duration: 365 days");
        TimeLockedDepositBox box = new TimeLockedDepositBox(lockDuration);
        _userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "TimeLocked");
        return address(box);
    }

    function nameBox(address boxAddress, string calldata name) public {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not box owner");
        _boxNames[boxAddress] = name;
        emit BoxNamed(boxAddress, name);
    }

    function storeSecret(address boxAddress, string calldata secret) public {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not box owner");
        box.storeSecret(secret);
    }

    function transferBoxOwnership(address boxAddress, address newOwner) public {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not box owner");
        box.transferOwnership(newOwner);

        address[] storage boxes = _userDepositBoxes[msg.sender];
        for (uint256 i = 0; i < boxes.length; i++) {
            if (boxes[i] == boxAddress) {
                boxes[i] = boxes[boxes.length - 1];
                boxes.pop();
                break;
            }
        }
        _userDepositBoxes[newOwner].push(boxAddress);
    }

    function getUserBoxes(address user) public view returns (address[] memory) {
        return _userDepositBoxes[user];
    }

    function getBoxName(address boxAddress) public view returns (string memory) {
        return _boxNames[boxAddress];
    }

    function getBoxInfo(address boxAddress) public view returns (
        string memory boxType,
        address owner,
        uint256 depositTime,
        string memory name
    ) {
        IDepositBox box = IDepositBox(boxAddress);
        return (
            box.getBoxType(),
            box.getOwner(),
            box.getDepositTime(),
            _boxNames[boxAddress]
        );
    }
}