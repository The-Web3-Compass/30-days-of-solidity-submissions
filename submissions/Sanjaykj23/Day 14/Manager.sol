pragma solidity ^0.8.10;
import "./IDepositBox.sol";
import "./BasicVault.sol";
import "./GoldVault.sol";
import "./PremiumVault.sol";

contract Manager{
    mapping(address => address[]) private userDepositBoxes;
    mapping(address => string) private boxNames;

    event BoxCreated(address indexed owner, address indexed boxAddress, string boxType);
    event BoxNamed(address indexed boxAddress, string name);

    function addBasicBox(address _owner) external returns(address){
        BasicVault box=new BasicVault(_owner);
        address boxAddress=address(box);
        emit BoxCreated(_owner,boxAddress,"Basc");
        userDepositBoxes[_owner].push(boxAddress);
        return boxAddress;
    }
    function addGoldBox(address _owner)external returns(address){
        GoldVault box=new GoldVault(_owner);
        address boxAddress=address(box);
        emit BoxCreated(_owner,boxAddress,"Basc");
        userDepositBoxes[_owner].push(boxAddress);
        return boxAddress;
    }
    function addPremiumBox(address _owner,uint interval, address beneficiery)external returns(address) {
        PremiumVault box=new PremiumVault(_owner,interval,beneficiery);
        address boxAddress=address(box);
        emit BoxCreated(_owner,boxAddress,"Basc");
        userDepositBoxes[_owner].push(boxAddress);
        return boxAddress;
    }
    function nameBox(address boxAddress,string memory name)external {
        IDepositBox newBox=IDepositBox(boxAddress);
        require(newBox.getOwner()==msg.sender,"Not an Owner");
        boxNames[boxAddress]=name;
        BoxNamed(boxAddress, name);
    }
    function storeSecrect(address boxAddress,string memory secMessage)external{
        IDepositBox newBox=IDepositBox(boxAddress);
        require(newBox.getOwner()==msg.sender,"Not an Owner");
        newBox.storeSecret(secMessage);
    }
    function transferBoxOwnership(address boxAddress,address newOwner)external{
        IDepositBox newBox=IDepositBox(boxAddress);
        require(newBox.getOwner()==msg.sender);
        newBox.transferOwnership(newOwner);
        address[] userBoxed=userDepositBoxes[newBox.getOwner()];
        for(uint i=0;i<userBoxed.length;i++){
            if(userBoxed[i]==boxAddress){
                userBoxed[i]=userBoxed[userBoxed.length-1];
                userBoxed.pop();
                break;
            }
        }
        userDepositBoxes[newOwner].push(boxAddress);
    }
}