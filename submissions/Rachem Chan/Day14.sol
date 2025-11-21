//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 
import "./IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {

    address private owner;
    string private secret;
    uint256 private depositTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretStored(address indexed owner);

    constructor(){
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    modifier onlyOwner(){
        require(owner == msg.sender, "Not the owner");
        _;
    }

    function getOwner() public view override returns (address){
        return owner;
    }

    function transferOwnership(address newOwner) external virtual override onlyOwner{
        require(newOwner != address(0), "Invalid Address");
        emit OwnershipTransferred(owner, newOwner); 
        owner = newOwner;
    }

    function storeSecret(string calldata _secret)external virtual override onlyOwner{
        secret = _secret;
        emit SecretStored(msg.sender);
    }

    function getSecret() public view virtual override onlyOwner returns (string memory){
        return secret;
    }

    function getDepositTime() external view virtual override onlyOwner returns (uint256) {
        return depositTime;
    }

    
   
    
    

}
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./BaseDepositBox.sol";

contract BasicDepositBox is BaseDepositBox{

    function getBoxType() external pure override returns(string memory){
        return "Basic";
    }
}
# Day 14
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";
import "./BasicDepositBox.sol";
import "./PremiumDepositBox.sol";
import "./TimeLockedDepositBox.sol";

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
        address[] storage boxes = userDepositBoxes[msg.sender];
        for(uint i = 0; i < boxes.length; i++){
            boxes[i] = boxes[boxes.length - 1];
            boxes.pop();
            break;
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

