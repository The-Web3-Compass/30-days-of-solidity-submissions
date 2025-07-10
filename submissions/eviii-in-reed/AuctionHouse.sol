//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ActionHouse {
    //address: hold the address of a user or a contract on the Ethereum network
    address public owner;
    string public item;
    uint256 public auctionEndTime;
    address private highestBidder;
    uint256 private highestBid;
    bool public ended;

    mapping (address => uint256) public bids;
    address[] public bidders;

    //contructor: automatically executes only once when a contract is deployed to the blockchain. 
    // It's used to initialize the contract's state variables and set up its initial state.
    constructor(string memory _item, uint256 _biddingTime){
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime; //block.timestamp is the current block time
    }

    // use external if expect that the function will only ever be called externally
    // use public if need to call the function internally
    function bid (uint256 amount) external {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(amount > 0, "Bid amount must be greater than 0!");// require(if,else)
        require(amount > bids[msg.sender], "Bids must be higher than current bid.");

        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

        bids[msg.sender] = amount;

        if (amount > highestBid){
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction was not ended yet.");
        require(!ended, "Auction end has already been called.");

        ended = true;
    }

    function winner() external view returns(address, uint256) {
        require(!ended, "Auction hasn't ended yet.");
        return(highestBidder, highestBid);
    }


    function getAllBidders() external view returns(address[] memory) {
        return bidders;
    }
}
