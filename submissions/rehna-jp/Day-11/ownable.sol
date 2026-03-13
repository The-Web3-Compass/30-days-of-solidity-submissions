// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Ownable {
    address private owner;
    address moderator;
    uint256 number;
    mapping(address => bool) public isModerator;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    bool withdrawalTime = true;

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyModerator() {
        require(isModerator[msg.sender], "Only moderator can perform this action");
        _;
    }

    function ownerAddress() public view returns (address) {
        return owner;
    }
    function setWithdrawalEnabled(bool status) external onlyModerator{
       withdrawalTime = status;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        address previous = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previous, _newOwner);
    }

    function squareNumber() external virtual returns(uint){
       
    }
}
