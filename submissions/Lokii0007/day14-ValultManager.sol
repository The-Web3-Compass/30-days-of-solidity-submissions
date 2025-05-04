// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "./day14-IDepositBox.sol";
import "./day14-BasicDepositBox.sol";
import "./day14-PremiumDepositBox.sol";
import "./day14-TimeLockedDeposit.sol";

contract VaultManager {
   mapping(address => address[]) private userDepositBoxes;
   mapping(address => string) private boxNames;

   event BoxCreated(address indexed owner, address indexed boxAddress, string boxType);
   event BoxNamed(address indexed boxAddress, string boxName);

   function createBasicBox()external returns(address){
       BasicDepositBox box = new BasicDepositBox();

       userDepositBoxes[msg.sender].push(address(box));
       emit BoxCreated(msg.sender, address(box), "Basic");
       return address(box);
   }

   function createPremiumBox()external returns(address){
       PremiumDepositBox box = new PremiumDepositBox();

       userDepositBoxes[msg.sender].push(address(box));
       emit BoxCreated(msg.sender, address(box), "premium");
       return address(box);
   }

   function createTimeLockedBox(uint _lockDuration)external returns(address){
       TimeLockedDepositBox box = new TimeLockedDepositBox(_lockDuration);

       userDepositBoxes[msg.sender].push(address(box));
       emit BoxCreated(msg.sender, address(box), "premium");
       return address(box);
   }

   function nameBox(address _boxAddress, string memory _name) external {
       IDepositBox box = IDepositBox(_boxAddress);

       require(msg.sender == box.getOwner(),"not the box owner");
       boxNames[_boxAddress] = _name;

       emit BoxNamed(_boxAddress, _name);
   }

   function storeSecret(address _boxAddress,string calldata _secret) external {
       IDepositBox box = IDepositBox(_boxAddress);

       require(msg.sender == box.getOwner(),"not the box owner");
       box.storeSecret(_secret);
   }

   function getSecret(address _boxAddress) external view returns(string memory) {
       IDepositBox box = IDepositBox(_boxAddress);

       require(msg.sender == box.getOwner(),"not the box owner");
       return box.getSecret();
   }

   function transferBoxOwnership(address _boxAddress, address _newOwner) external {
       IDepositBox box = IDepositBox(_boxAddress);

       require(msg.sender == box.getOwner(),"not the box owner");
       box.transferOwnership(_newOwner);

       address[] storage boxes = userDepositBoxes[msg.sender];
       for(uint i=0; i<boxes.length;i++){
          if(boxes[i] == _boxAddress) {
            boxes[i] = boxes[boxes.length-1];
            boxes.pop();
            break;
          }
       }
       userDepositBoxes[_newOwner].push(_boxAddress);
   }

   function getUserDepositBoxes() external view returns(address[] memory){
    return userDepositBoxes[msg.sender];
   }

   function getBoxeName() external view returns(string memory){
    return boxNames[msg.sender];
   }

}