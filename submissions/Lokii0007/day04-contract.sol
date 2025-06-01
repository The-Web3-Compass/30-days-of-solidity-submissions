// SPDX-License-Identifier:MIT

contract AuctionHouse {
    address public owner;
    string public item;
    uint public auctionEndTime;
    address private highestBidder;
    uint private highestBid;
    bool public ended;

    mapping(address => uint) public bids;
    address[] public bidders;

    constructor(string memory _item, uint _endTime) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _endTime;
    }

    function bid(uint _amount) external {
        require(
            block.timestamp <= auctionEndTime,
            "AuctionHouse: auction has already ended"
        );
        require(
            _amount > 0,
            "AuctionHouse: bid amount should be greater than 0"
        );
        require(
            _amount > bids[msg.sender],
            "AuctionHouse: New bids must be gigher than previous bids"
        );

        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

        bids[msg.sender] = _amount;

        if (_amount > highestBid) {
            highestBid = _amount;
            highestBidder = msg.sender;
        }
    }

    function endAuction() external {
        require(
            block.timestamp > auctionEndTime,
            "AuctionHouse: auction has not ended yet."
        );
        require(!ended, "AuctionHouse: auction end has already been called");

        ended = true;
    }

    function getWinner() external view returns (address, uint) {
        require(ended, "AuctionHouse: auction has not ended yet.");
        return (highestBidder, highestBid);
    }

    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }
}
