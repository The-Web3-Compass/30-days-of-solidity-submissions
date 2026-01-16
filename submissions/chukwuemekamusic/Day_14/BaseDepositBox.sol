// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IDepositBox} from "./IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {
    error BaseDeposit_UnAuthorized();
    error BaseDeposit_AlreadyStored();
    error BaseDeposit_ZeroValue();
    
    address public owner;
    string private secret;
    uint256 private depositTime;

    event OnwershipTransfered(address indexed oldOwner, address indexed newOwner);
    event SecretStored(address indexed owner, uint256 storedTime);
    event SecretUpdated(address indexed owner, uint256 updatedTime);

    modifier onlyOwner {
        if (msg.sender != owner) revert BaseDeposit_UnAuthorized();
        _;
    }

    constructor(){
        owner = msg.sender;
        depositTime = block.timestamp;
     }

    function storeSecret(string calldata _secret) external virtual override onlyOwner{
        if (!_isEqual(secret, "")) revert BaseDeposit_AlreadyStored();
        secret = _secret;
        emit SecretStored(owner, block.timestamp);

    }

    function updateSecret(string calldata _secret) external virtual override onlyOwner{
        if (_isEqual(secret, _secret)) return;
        secret = _secret;
        emit SecretUpdated(owner, block.timestamp);
    }

    
    function transferOwnership(address newOwner) external virtual override onlyOwner {
        if (newOwner == address(0)) revert BaseDeposit_ZeroValue();
        if (newOwner == owner) return;
        address oldOwner = owner;
        owner = newOwner;
        emit OnwershipTransfered(oldOwner, newOwner);
     }
     
    function getSecret() public view virtual override onlyOwner returns(string memory) {
        return _revealSecret();
    }
    function _revealSecret() internal view returns(string memory) {
        return secret;
    }
    function getDepositTime() external view virtual override onlyOwner returns(uint256){
        return depositTime;
    }
    function getOwner() external view virtual override onlyOwner returns(address){
        return owner;
    }
    function isOwner(address account) external view returns (bool){
        return account==owner;
    }

    function _isEqual(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}