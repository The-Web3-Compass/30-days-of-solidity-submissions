// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//Cat House System:
//When cat owners go out, they can board their cats in this cat house. 
//Each room (cat) is registered by the owner. 
//Guests pay ETH to the contract (specifying the room).
//The owner can approve specific guests to access (“open the door”) and pet the cat, and withdraw ETH.
contract CatHouse {
    //roomID -> Owner address
    mapping(uint256 => address) public roomOwners;
    //roomID -> Owner address -> Payments
    mapping(uint256 => mapping(address => uint256)) public payments;
    //roomID -> Owner address -> Approve status
    mapping(uint256 => mapping(address => bool)) public accessApproved;
    //roomID -> Funds
    mapping(uint256 => uint256) public roomFunds;

    //Events：listening from frontend
    event RoomRegistered(uint256 indexed roomId, address owner);
    event PaymentMade(uint256 indexed roomId, address payer, uint256 amount);
    event AccessApproved(uint256 indexed roomId, address guest, bool approved);
    event FundsWithdrawn(uint256 indexed roomId, address owner, uint256 amount);

    //RegisterRoom
    function registerRoom(uint256 roomId) external {
        require(roomOwners[roomId] == address(0), "Room already registered");
        roomOwners[roomId] = msg.sender;
        emit RoomRegistered(roomId, msg.sender);
    }

    //Guest pay
    function payForAccess(uint256 roomId) external payable {
        require(roomOwners[roomId] != address(0), "Room not registered");
        require(msg.value > 0, "Payment must be greater than 0");
        
        payments[roomId][msg.sender] += msg.value;
        roomFunds[roomId] += msg.value;
        emit PaymentMade(roomId, msg.sender, msg.value);
    }

    //Approve
    function approveAccess(uint256 roomId, address guest, bool approved) external {
        require(roomOwners[roomId] == msg.sender, "Not the room owner");
        require(payments[roomId][guest] > 0, "Guest has not paid");
        
        accessApproved[roomId][guest] = approved;
        emit AccessApproved(roomId, guest, approved);
    }

    //Withdraw
    function withdrawFunds(uint256 roomId) external {
        require(roomOwners[roomId] == msg.sender, "Not the room owner");
        uint256 amount = roomFunds[roomId];
        require(amount > 0, "No funds to withdraw");
        
        roomFunds[roomId] = 0;
        payable(msg.sender).transfer(amount);
        emit FundsWithdrawn(roomId, msg.sender, amount);
    }

    //query: if is not approved
    function isAccessApproved(uint256 roomId, address guest) external view returns (bool) {
        return accessApproved[roomId][guest];
    }

    //query: amount
    function getPayment(uint256 roomId, address guest) external view returns (uint256) {
        return payments[roomId][guest];
    }
}
