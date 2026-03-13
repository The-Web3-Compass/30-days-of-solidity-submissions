// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AuctionHouse {
    event BidPlaced(address bidder, uint256 amount);
    event FundReclaimed(address bidder, uint256 amountRefunded);
    event WinningsTransferred(address recipient, uint256 winningsAmount);

    error AuctionHouse__BidTooLow();
    error AuctionHouse__NoItemAdded();
    error AuctionHouse__AuctionEnded();
    error AuctionHouse__NotAuthorized();
    error AuctionHouse__AuctionOngoing();
    error AuctionHouse__TransferFailed();

    string public item;
    uint256 private auctionEnds;
    address private highestBidder;
    uint256 private maxBidAmount;
    address private immutable i_owner;
    mapping(address => uint256) private bidAmounts;

    constructor(string memory _item, uint256 _biddingTime) {
        i_owner = msg.sender;
        if (bytes(_item).length == 0) revert AuctionHouse__NoItemAdded();
        item = _item;
        auctionEnds = block.timestamp + _biddingTime;
    }

    function placeBid() public payable auctionOngoing {
        uint256 newTotalBid = bidAmounts[msg.sender] + msg.value;

        if (newTotalBid <= maxBidAmount) {
            revert AuctionHouse__BidTooLow();
        }

        bidAmounts[msg.sender] = newTotalBid;
        maxBidAmount = newTotalBid;
        highestBidder = msg.sender;

        emit BidPlaced(msg.sender, msg.value);
    }

    function claimRefund() public auctionEnded {
        if (msg.sender == highestBidder) {
            revert AuctionHouse__NotAuthorized();
        }

        uint256 amount = bidAmounts[msg.sender];
        if (amount == 0) {
            return;
        }

        bidAmounts[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");

        if(!success){
            revert AuctionHouse__TransferFailed();
        }
        emit FundReclaimed(msg.sender, amount);
    }

    function withdrawWinnings() public owner auctionEnded{
        uint256 amount = maxBidAmount;
        maxBidAmount = 0;
        (bool success, ) = msg.sender.call{value: amount}("");

        if(!success){
            revert AuctionHouse__TransferFailed();
        }
        emit WinningsTransferred(msg.sender, amount);
    }

    function showWinner() public view auctionEnded returns (address, uint256) {
        if(highestBidder == address(0)) revert AuctionHouse__NoItemAdded();
        return (highestBidder, maxBidAmount);
    }

    function getBiddingAmountOfAUser(
        address _user
    ) public view returns (uint256) {
        return bidAmounts[_user];
    }

    function getAuctionedItem() public view returns (string memory) {
        return item;
    }

    function getHighestBid() public view returns (uint256) {
        return maxBidAmount;
    }

    function getHighestBidder() public view returns (address) {
        return highestBidder;
    }

    modifier owner() {
        if (msg.sender != i_owner) revert AuctionHouse__NotAuthorized();
        _;
    }

    modifier auctionOngoing() {
        if (block.timestamp >= auctionEnds) revert AuctionHouse__AuctionEnded();
        _;
    }

    modifier auctionEnded() {
        if (block.timestamp < auctionEnds)
            revert AuctionHouse__AuctionOngoing();
        _;
    }
}