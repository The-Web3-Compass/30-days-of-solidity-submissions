// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
contract Ownable {//继承
    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }


    modifier onlyOwner() {
         require(msg.sender == owner, "Only owner can perform this action");
        _;
    }


    function ownerAddress() public view returns (address) {
        return owner;
    }
//- `msg.sender`（发送者的地址），- 和 `msg.value`（发送的 ETH 数量）。
    function transferOwnership(address _newOwner) public onlyOwner {
       require (_newOwner !=address(0), "Invalid address"); 
        address previous = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previous, _newOwner);

    }
}