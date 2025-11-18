//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;
// BaseDepositBox.sol - abstract contract
//     It is shared foundation which will implement most of the logic defined in the interface like secret storage, ownership and deposit time.

// Abstract contract:
// An abstract contract is a contract declared with the abstract keyword that contains at least one function without an implementation.
// It requires child contracts to provide concrete implementations via override before deployment is permitted.
import "./Day14IDepositBox.sol";

// This contract is the core of deposit box system which handles the common logic.
// The key word "abstract" means that this contract cannot be deployed directly. It is designed to act like a template or foundation for other contracts to build on.
abstract contract BaseDepositBox is IDepositBox{
    address private owner;// Stores the address of the person who owns this deposit box. Only this person is allowed to store or retrieve secrets.
    string private secret;
    uint256 private depositTime;

    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);
    event SecretStored(address indexed owner);

    constructor(){
        owner=msg.sender;
        depositTime=block.timestamp;
    }

    modifier onlyOwner(){
        require(owner==msg.sender,"Not the owner");
        _;

    }

    // override from the IDepositBox
    function getOwner() public view override returns(address){
        return owner;
    }

    // override from the IDepositBox
    function transferOwnership(address newOwner) external virtual override onlyOwner{
        require(newOwner!=address(0),"Invalid Address");
        emit OwnershipTransferred(owner,newOwner);
        owner=newOwner;
    }

    // override from the IDepositBox
    function storeSecret(string calldata _secret) external virtual override onlyOwner{
        secret=_secret;
        emit SecretStored(msg.sender);
    }

    // override from the IDepositBox
    function getSecret() public view virtual override onlyOwner returns(string memory){
        return secret;
    }

    // override from the IDepositBox
    function getDepositTime() external view virtual override onlyOwner returns(uint256){
        return depositTime;
    }
    
}