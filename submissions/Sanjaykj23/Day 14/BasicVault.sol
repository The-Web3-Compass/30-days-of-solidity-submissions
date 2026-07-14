pragma solidity ^0.8.10;
import './BaseDeposit.sol';
contract BasicVault is BaseDeposit {
    constructor(address _owner){
        box.owner = _owner;
        box.BoxType="Basic";
    }
    function getBoxType()external pure override returns(string memory){
        return box.BoxType;
    }
}