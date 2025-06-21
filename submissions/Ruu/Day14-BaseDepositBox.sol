//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {
    address private Owner;
    string private secret;
    uint256 private DepositTime;

    event OwnershipTransferred(address indexed PreviousOwner,address indexed NewOwner);
    event SecretStored(address indexed Owner);

    constructor(){
        Owner = msg.sender;
        DepositTime = block.timestamp;

    }

    modifier OnlyOwner(){
        require(Owner == msg.sender, "Not the owner");
        _;

    }

    function GetOwner() public view override returns(address){
        return Owner;

    }

    function TransferOwnership(address NewOwner) external virtual override OnlyOwner{
        require(NewOwner != address(0), "Invalid address");
        emit OwnershipTransferred(Owner, NewOwner);
        Owner = NewOwner;

    }

    function StoreSecret(string calldata _secret) external virtual override  OnlyOwner{
        secret = _secret;
        emit SecretStored(msg.sender);

    }

    function GetSecret() public view virtual override OnlyOwner returns(string memory){
        return secret;

    }

    function GetDepositTime() external view virtual override OnlyOwner returns(uint256){
        return DepositTime;

    }

}
