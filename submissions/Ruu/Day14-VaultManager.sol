//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";
import "./BasicDepositBox.sol";
import "./PremiumDepositBox.sol";
import "./TimeLockedDepositBox.sol";

contract VaultManager{

    mapping(address => address[]) private UserDepositBoxes;
    mapping(address => string) private BoxNames;

    event BoxCreated(address indexed Owner, address indexed BoxAddress, string BoxType);
    event BoxNamed(address indexed Boxaddress,string name);

    function CreateBasicBox() external returns(address){
        BasicDepositBox box = new BasicDepositBox();
        UserDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Basic");
        return address(box);

    }

    function CreatePremiumBox() external returns(address){
        PremiumDepositBox box = new PremiumDepositBox();
        UserDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Premium");
        return address(box);
        
    }

    function CreateTimeLockedBox(uint256 LockDuration) external returns(address){
        TimeLockedDepositBox box = new TimeLockedDepositBox(LockDuration);
        UserDepositBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Time Locked");
        return address(box);
        
    }

    function NameBox(address boxAddress, string memory name) external{
        IDepositBox box = IDepositBox(boxAddress);
        require(box.GetOwner() == msg.sender, "Not the box owner");
        BoxNames[boxAddress] = name;
        emit BoxNamed(boxAddress, name);

    }

    function StoreSecret(address boxAddress, string calldata secret) external{
        IDepositBox box = IDepositBox(boxAddress);
        require(box.GetOwner() == msg.sender, "Not the box owner");
        box.StoreSecret(secret);

    }

    function TransferBoxOwnership(address boxAddress, address NewOwner) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.GetOwner() == msg.sender, "Not the box owner");
        box.TransferOwnership(NewOwner);
        address[] storage boxes = UserDepositBoxes[msg.sender];
        for(uint i = 0; i < boxes.length; i++){
            if(boxes[i] == boxAddress){
            boxes[i] = boxes[boxes.length - 1];
            boxes.pop();
            break;
            }
        }
        UserDepositBoxes[NewOwner].push(boxAddress);

    }

    function GetUserBoxes(address user) external view returns(address[] memory){
        return UserDepositBoxes[user];

    }

    function GetBoxName(address boxAddress) external view returns(string memory){
        return BoxNames[boxAddress];

    }

    function GetBoxInfo(address boxAddress) external view returns(
        string memory BoxType,
        address Owner,
        uint256 DepositTime,
        string memory name
    ){
        IDepositBox box = IDepositBox(boxAddress);
        return(
            box.GetBoxType(),
            box.GetOwner(),
            box.GetDepositTime(),
            BoxNames[boxAddress]
        );

    }

}
