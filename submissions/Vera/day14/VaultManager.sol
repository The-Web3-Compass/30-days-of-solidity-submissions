// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IDepositBox.sol";
import "./BasicDepositBox.sol";
import "./PremiumDepositBox.sol";
import "./TimeLockedDepositBox.sol";

contract VaultManager {
    mapping(address => address[]) private userDepositBoxes;
    mapping(address => string) private boxNames;

    event BoxCreated(address indexed owner,address indexed boxAddress, string boxType);
    event BoxNamed(address indexed boxAddress,string boxNames);

    function createBasicBox()external returns(address){
        BasicDepositBox box = new BasicDepositBox(msg.sender);
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Basic");
        return address(box);
    }

    function createPremiumBox()external returns(address){
        PremiumDepositBox box = new PremiumDepositBox(msg.sender);
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Premium");
        return address(box);
    }

    function createTimeLockedBox(uint256 _lockDuration)external returns(address){
        TimeLockedDepositBox box = new TimeLockedDepositBox(msg.sender,_lockDuration);
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "TimeLocked");
        return address(box);
    }

    function nameBox(address _boxAddress,string calldata _name)external{
        IDepositBox box = IDepositBox(_boxAddress);
        require(box.getOwner() == msg.sender,"Not the box owner");
        boxNames[_boxAddress] = _name;
        emit BoxNamed(_boxAddress, _name);
    }

    function storeSecret(address _boxAddress,string calldata _secret)external {
        IDepositBox box = IDepositBox(_boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        box.storeSecret(_secret);
    }

    function transferBoxOwnership(address _boxAddress, address newOwner)external {
        require(newOwner!=address(0),"New owner is a valid address");
        IDepositBox box = IDepositBox(_boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        box.transferOwnership(newOwner);

        address[] storage boxes = userDepositBoxes[msg.sender];
        for(uint i=0;i<boxes.length;i++){
            if(boxes[i] == _boxAddress){
                boxes[i] = boxes[boxes.length -1];
                boxes.pop();
                break;
            }
        }
        userDepositBoxes[newOwner].push(address(_boxAddress));
    }

    function getUserBoxes(address user) external view returns (address[] memory) {
        return userDepositBoxes[user];
    }

    function getBoxName(address boxAddress) external view returns (string memory) {
        return boxNames[boxAddress];
    }

    function getBoxInfo(address boxAddress) external view returns (
        string memory boxType,
        address owner,
        uint256 depositTime,
        string memory name
    ) {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        return (
            box.getBoxType(),
            box.getOwner(),
            box.getDepositTime(),
            boxNames[boxAddress]
        );
    }

}