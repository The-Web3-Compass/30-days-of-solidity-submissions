// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "./day14-IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {
    address private owner;
    string private secret;
    uint256 private depositTime;

    event OnwershipTransferred(address indexed prevOwner, address indexed newOwner);
    event SecretStored(address indexed owner);

    modifier onlyOwner(){
        require(msg.sender == owner, "unauthorized");
        _;
    }

    constructor(){
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    function getOwner() public view override returns(address){
        return owner;
    }

    function transferOwnership(address _newOwner) external virtual override onlyOwner {
       address prevOwner = owner;
       owner = _newOwner;

       emit OnwershipTransferred(prevOwner, _newOwner);
    }

    function storeSecret(string calldata _secret) external virtual override onlyOwner {
        secret = _secret;

        emit SecretStored(msg.sender);
    }

    function getSecret()public view virtual override onlyOwner returns(string memory){
        return secret;
    }

    function getDepositTime()external view virtual override onlyOwner returns(uint){
        return depositTime;
    }
}