// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AuctionHouse {
    address public immutable owner;

    error AuctionHouse__endAuctionTimeMustBeInFuture();
    error AuctionHouse__InvalidAuctionId();
    error AuctionHouse__OwnerCannotBidItsOwnAuction();
    error AuctionHouse__AmountMustBiggerThenHighestBid();
    error AuctionHouse__AuctionIsStillLive();
    error AuctionHouse__OnlyOwnerCanCall();
    error AuctionHouse__TransaferFail();

    event AuctionCreated(uint256 indexed auctionId, address indexed auctionOwner);
    event UserBidOnAuction(address indexed bidders, uint256 indexed auctionId, uint256 bidAmount);

    struct s_auctionProduct {
        string name;
        address payable highestBidder;
        uint256 highestBid;
        uint256 endTime;
        address[] bidders;
        address auctionOwner;
    }

    constructor() {
        owner = msg.sender;
    }

    mapping(address => mapping(uint256 => uint256)) public s_bidAmountOnAuction; // this maaping can tract the amount of bidding on every auciton which user choose?
    mapping(uint256 => address[]) public s_biddersOnAuctions;

    s_auctionProduct[] public auctions;

    function createAuction(string memory _name, uint256 _durationInSeconds) public {
        if (block.timestamp > (block.timestamp + _durationInSeconds)) {
            revert AuctionHouse__endAuctionTimeMustBeInFuture();
        }

        auctions.push(
            s_auctionProduct({
                name: _name,
                endTime: block.timestamp + _durationInSeconds,
                highestBid: 0,
                auctionOwner: msg.sender,
                highestBidder: payable(address(0)),
                bidders: new address[](0)
            })
        );

        emit AuctionCreated(auctions.length - 1, msg.sender);
    }

    function BidOnAuction(uint256 _auctionId) public payable {
        s_auctionProduct memory auction = auctions[_auctionId];

        if (auction.auctionOwner == address(0)) {
            revert AuctionHouse__InvalidAuctionId();
        }

        if (auction.auctionOwner == msg.sender) {
            revert AuctionHouse__OwnerCannotBidItsOwnAuction();
        }
        if (msg.value <= auction.highestBid) {
            revert AuctionHouse__AmountMustBiggerThenHighestBid();
        }
        uint256 prvsBalance = s_bidAmountOnAuction[msg.sender][_auctionId];

        auction.highestBid = msg.value + prvsBalance;
        s_bidAmountOnAuction[msg.sender][_auctionId] = auction.highestBid;
        auction.highestBidder = payable(msg.sender);
        // auction.bidders.push(msg.sender);
        auctions[_auctionId] = auction;
        s_biddersOnAuctions[_auctionId].push(msg.sender);
        emit UserBidOnAuction(msg.sender, _auctionId, msg.value);
    }

    function getFinilizedWinner(uint256 _auctionId) public returns (address) {
        s_auctionProduct memory auction = auctions[_auctionId];
        if (auction.endTime < block.timestamp) {
            revert AuctionHouse__AuctionIsStillLive();
        }
        if (auction.auctionOwner == address(0)) {
            revert AuctionHouse__InvalidAuctionId();
        }
        if (auction.auctionOwner != msg.sender) {
            revert AuctionHouse__OnlyOwnerCanCall();
        }
        (bool success,) = payable(auction.auctionOwner).call{value: auction.highestBid}("");
        if (!success) {
            revert AuctionHouse__TransaferFail();
        }

        return auction.highestBidder;
    }
}
