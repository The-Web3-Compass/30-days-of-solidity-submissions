// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Ownable {
  
    address private _owner;
    
    event OwnershipTransferred(
        address indexed previousOwner, 
        address indexed newOwner
    );
    
    event OwnershipRenounced(
        address indexed previousOwner
    );

    error NotOwner(address caller, address owner);
    error InvalidNewOwner(address newOwner);
    error AlreadyOwner(address account);
    
    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert NotOwner(msg.sender, _owner);
        }
        _;
    }
 
    function owner() public view virtual returns (address ownerAddress) {
        return _owner;
    }
 
    function isOwner(address account) public view returns (bool isOwnerResult) {
        return account == _owner;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
 
        if (newOwner == address(0)) {
            revert InvalidNewOwner(newOwner);
        }
        
        if (newOwner == _owner) {
            revert AlreadyOwner(newOwner);
        }
        
        _transferOwnership(newOwner);
    }
   
    function renounceOwnership() public virtual onlyOwner {
        address previousOwner = _owner;
        _owner = address(0);
        
        emit OwnershipRenounced(previousOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}