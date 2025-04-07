// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/** 
 * @title AuctionHouse
 * @author shivam
 * @notice A simple contract to run an auction with predefined end time.
 *   How it works:
     - When the contract is created, it sets auction end time by constructor.
     - Bids are allowed until the auction is ended.
     - Any new bid must be higher than the current winning bid.
     - The current winning bid is hidden until the auction is ended, after which it can be read.
     - At the end of auction, the current winning bid will be the winner.
 */
contract AuctionHouse {
    /// @notice Error thrown when invalid end time, i.e., past time is provided in constructor.
    /// @param _endTime Provided auction end time
    error InvalidEndTime(uint256 _endTime);

    /// @notice Error thrown when bid amount is not more than the current winning bid amount
    /// @param _amount Bid amount attempted
    error InvalidBidAmount(uint256 _amount);

    /// @notice Error thrown when auction has already ended
    /// @param _blockTime Current block create time against which end time is checked.
    error AuctionEnded(uint256 _blockTime);

    /// @notice Error thrown when auction has not ended yet
    /// @param _blockTime Current block create time against which end time is checked.
    error AuctionNotEnded(uint256 _blockTime);

    /// @notice Event emitted when a new bid is placed.
    /// @dev amount is not shown intentionally as that will allow to cheat.
    event BidPlaced();

    /// @notice auction end time in unix epoch
    uint256 private auctionEndTime; 

    /// @notice Mapping of user's address to bid placed
    mapping (address => uint256) private bids;

    /// @notice address of user with maximum bid at a given time
    address private currentWinner;

    /// @notice Initializes the contract by setting auction end time
    /// @param _endTime Auction end time in unix epoch
    constructor(uint256 _endTime) {
        if (_endTime <= block.timestamp) {
            revert InvalidEndTime(_endTime);
        }
        auctionEndTime = _endTime;
    }

    /// @notice get auction end time
    /// @return auctionEndTime auction end time in unix epoch
    function getEndTime() public view returns (uint256) {
        return auctionEndTime;
    }

    /// @notice get bid placed by sender
    /// @return amount Bid amount placed by sender
    function getBid() public view returns (uint256) {
        return bids[msg.sender];
    }

    /// @notice get winner details after auction has ended. It will return address(0) if no winners.
    /// @return _winner Address of winning user
    /// @return _amount Bid amount of winning use
    /// @custom:error AuctionNotEnded if auction has not ended yet
    function getWinner() public view returns (address _winner, uint256 _amount) {
        if (auctionEndTime >= block.timestamp) {
            revert AuctionNotEnded(block.timestamp);
        }
        _winner = currentWinner;
        _amount = bids[currentWinner];
    }

    /// @notice Place bid with given amount. If a bid already exists, it will be overridden.
    /// @param _amount Bid amount
    /// @custom:error AuctionEnded if auction has already ended
    /// @custom:error InvalidBidAmount if `_amount` is not more than current winning bid amount
    function placeBid(uint256 _amount) public {
        // only allow bids if auction open
        if (auctionEndTime < block.timestamp) {
            revert AuctionEnded(block.timestamp);
        }
        // do not allow lower bids
        if (currentWinner != address(0) && _amount <= bids[currentWinner]) {
            revert InvalidBidAmount(_amount);
        }
        
        // place bid by sender
        bids[msg.sender] = _amount;
        currentWinner = msg.sender;

        // emit event
        emit BidPlaced();
    }
}