// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day14-IDepositBox.sol";
import "./Day14-BasicDepositBox.sol";
import "./Day14-TimeLockedDepositBox.sol";
import "./Day14-PremiumDepositBox.sol";

contract Vaultmanager{
    mapping (address => address[]) private userDepositBoxes;//该用户所有的存款箱
    mapping (address => string) private boxnames;

    event boxCreated(address indexed owner, address indexed boxAddress, string boxType);
    event boxNamed(address indexed boxAddress, string name);

    // 如下是创建三个存款箱子
    function createBasicBox() external returns(address){
        BasicDepositBox box = new BasicDepositBox();
        userDepositBoxes[msg.sender].push(address(box));
        emit boxCreated(msg.sender, address(box), "Basic");
        return address(box);
    }

    function createPremiumDepositBox() external returns(address){
        PremiumDepositBox box = new PremiumDepositBox();
        userDepositBoxes[msg.sender].push(address(box));
        emit boxCreated(msg.sender, address(box), "PremiumDeposit");
        return address(box);
    }

    function createTimeLockedDepositBoxBox(uint256 lockDuration) external returns(address){
        TimeLockedDepositBox box = new TimeLockedDepositBox(lockDuration);
        userDepositBoxes[msg.sender].push(address(box));
        emit boxCreated(msg.sender, address(box), "TimeLockedDepositBox");
        return address(box);
    }

    // 箱子名更新
    function nameBox(address _boxAddress, string calldata name)external {
        IDepositBox box = IDepositBox(_boxAddress);//不可以用new来实例化接口
        require(box.getOwner() == msg.sender,"Not the box owner");
        boxnames[_boxAddress] = name;
        emit boxNamed(_boxAddress, name);
    }


    function storeSecret(address _boxAddress, string calldata secret) external {
        IDepositBox box = IDepositBox(_boxAddress);
        require(box.getOwner()==msg.sender,"Not the box owner");
        box.storeSecret(secret);
    }

    function transferBoxOwnership(address _boxAddress, address newOwner) external {
        IDepositBox box = IDepositBox(_boxAddress);
        require(box.getOwner() == msg.sender, "Not the box owner");

        box.transferOwnership(newOwner);

        // 从旧所有者处移除金库
        address[] storage boxes = userDepositBoxes[msg.sender];
        for (uint i = 0; i < boxes.length; i++) {
            if (boxes[i] == _boxAddress) {
                boxes[i] = boxes[boxes.length - 1];
                boxes.pop();
                break;
            }
        }

        // 将金库添加到新所有者
        userDepositBoxes[newOwner].push(_boxAddress);
    }
    
    function getUserBoxes(address user) external view returns (address[] memory) {
        return userDepositBoxes[user];
    }

    function getBoxName(address boxAddress) external view returns (string memory) {
        return boxnames[boxAddress];
    }

    function getBoxInfo(address boxAddress) external view returns (
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
            boxnames[boxAddress]
        );
    }

}