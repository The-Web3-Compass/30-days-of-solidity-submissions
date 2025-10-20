// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Day14-IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {
    /** 
    abstract:This contract cannot be deployed directly.
    It’s designed to act like a template or foundation for other contracts to build on.
    And it dosn't fully implement every function required by the interface. 
    */

    address private owner;
    string private secret;
    uint256 private depositTime;

    event OwnershipTransfered(address indexed oldOwner,address indexed newOwner,uint256 timestamp);
    event SecretStored(address indexed owner);

    constructor() {
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"Not the box owner");
        _;
    }

    /**
    virtual:Virtual means it can be overridden by a child
    */
    function getOwner() external view override returns(address){
        return owner;
    }

    function transferOwnership(address newOwner) onlyOwner external{
        require(newOwner != address(0),"Invaild address");
        emit OwnershipTransfered(owner,newOwner,block.timestamp);
        owner = newOwner;     

    }

    function storeSecret(string calldata _secret) external virtual override onlyOwner {
        secret = _secret;
        emit SecretStored(msg.sender);
    }

    function getSecret() public view virtual override onlyOwner returns (string memory){
        return secret;
    }



    function getDepositTime() external view virtual override onlyOwner returns(uint256){
        return depositTime;
    }


}