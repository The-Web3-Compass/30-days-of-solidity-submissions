//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./day14-IDepositBox.sol";
abstract contract BaseDepositBox is IDepositBox{
    address private owner;
    string private secret;
    uint256 private depositTime;

    event OwnerShipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretStored(address indexed owner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this action");
        _;
    }

    constructor() {
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    function getOwner() public view override returns(address) {
        return owner;
    }

    function transferOwnerShip(address _newOwner) external virtual override onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        emit OwnerShipTransferred(owner, _newOwner);
        owner = _newOwner;       
    }

    function storeSecret(string calldata _secret) external virtual override onlyOwner {
        secret = _secret;
        emit SecretStored(owner);
    }

    function getSecret() public view virtual override onlyOwner returns(string memory) {
        return secret;
    }

    function getDepositTime() external view virtual override returns (uint256) {
        return depositTime;
    }  
}
