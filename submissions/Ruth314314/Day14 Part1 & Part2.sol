//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

interface IDepositBox {

    function getOwner() external view returns(address);
    function transferOwnership(address newOwner)external;
    function storeSecret(string calldata secret)external;
    function getSecret() external view returns (string memory);
    function getBoxType() external pure returns(string memory);
    function getDepositTime() external view returns(uint256);
}

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

contract BasicDepositBox is BaseDepositBox{

    function getBoxType() external pure override returns(string memory){
        return "Basic";
    }
}

}
