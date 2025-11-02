// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day14_IDepositBox.sol";
import "./Day14_BasicDepositBox.sol";
import "./Day14_PremiumDepositBox.sol";
import "./Day14_TimeLockedDepositBox.sol";

contract VaultManager{

    mapping(address => address[]) private userDepositBoxes;
    mapping(address => string)private boxNames;

    event BoxCreated(address indexed owner, address indexed boxAdress, string boxType);
    event BoxNamed(address indexed boxAdress, string name);

    function createBasicBox() external returns (address){

        BasicDepositBox box = new BasicDepositBox();
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Basic");
        return address(box);
    }

    function createPremiumBox() external returns (address){

        PremiumDepositBox box = new PremiumDepositBox();
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Premium");
        return address(box);
    }

    function createTimeLockedBox(uint256 lockDuration) external returns (address){
        TimeLockedDepositBox box = new TimeLockedDepositBox(lockDuration);
        userDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Time Locked");
        return address(box);
    }

    function nameBox(address boxAddress, string memory name ) external{
        //这让我们可以在存款箱上调用 getOwner()，而无需知道它是什么类型。
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        boxNames[boxAddress] = name;
        emit BoxNamed(boxAddress, name);

    }

    function storeSecret(address boxAddress, string calldata secret) external{
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        box.storeSecret(secret);
    }

    function transferBoxOwnership(address boxAddress, address newOwner)  external{
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");
        box.transferOwnership(newOwner);
        //在旧所有者处移除
        address[] storage boxes = userDepositBoxes[msg.sender];
        for(uint i = 0; i < boxes.length; i++){
            if (boxes[i] == boxAddress) {//如果当前元素 boxes[i] 等于传入的 boxAddress（需要删除的元素），则执行删除操作。
            boxes[i] = boxes[boxes.length - 1];//将数组的 最后一个元素（boxes[boxes.length - 1]）移到 当前元素的位置（boxes[i]）。
            boxes.pop();//pop() 会删除数组的 最后一个元素。
            break;
    }
        }
        userDepositBoxes[newOwner].push(boxAddress);
      
    }

    function getUserBoxes(address user) external view returns(address[] memory){
        return userDepositBoxes[user];
    }

    function getBoxName(address boxAddress) external view returns (string memory) {
    return boxNames[boxAddress];
}

    function getBoxInfo(address boxAddress)external view returns(
        string memory boxType,
        address owner,
        uint256 depositTime,
        string memory name
    ){
        IDepositBox box = IDepositBox(boxAddress);
        return(
            box.getBoxType(),
            box.getOwner(),
            box.getDepositTime(),
            boxNames[boxAddress]
        );
    }

}

    


    
