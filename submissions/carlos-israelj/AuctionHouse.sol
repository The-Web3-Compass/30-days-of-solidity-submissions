// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.26;

/**
 * @title AuctionHouse
 * @author Carlos I Jimenez
 * @notice A simple auction contract where users can bid and the highest bidder wins
 * @dev Implements basic auction functionality with time-based control
 */
contract AuctionHouse {
    
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    /// @notice The address of the highest bidder
    address public s_highestBidder;
    
    /// @notice The current highest bid amount
    uint256 public s_highestBid;
    
    /// @notice The timestamp when the auction ends
    uint256 public s_auctionEndTime;
    
    /// @notice Whether the auction has ended
    bool public s_auctionEnded;
    
    /// @notice The owner/beneficiary of the auction
    address public s_owner;
    
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Emitted when a new highest bid is placed
    /// @param bidder The address of the bidder
    /// @param amount The bid amount
    event NewHighestBid(address indexed bidder, uint256 amount);
    
    /// @notice Emitted when the auction ends
    /// @param winner The address of the winning bidder
    /// @param amount The winning bid amount
    event AuctionEnded(address indexed winner, uint256 amount);
    
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Thrown when trying to bid after auction has ended
    error AuctionHouse__AuctionAlreadyEnded();
    
    /// @notice Thrown when bid is not higher than current highest bid
    error AuctionHouse__BidNotHighEnough();
    
    /// @notice Thrown when trying to end auction before end time
    error AuctionHouse__AuctionNotYetEnded();
    
    /// @notice Thrown when trying to end an already ended auction
    error AuctionHouse__AuctionEndAlreadyCalled();
    
    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Initializes the auction with a duration
     * @dev Sets the auction end time based on current timestamp + duration
     * @param _biddingTime The duration of the auction in seconds
     */
    constructor(uint256 _biddingTime) {
        s_owner = msg.sender;
        s_auctionEndTime = block.timestamp + _biddingTime;
    }
    
    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Place a bid on the auction
     * @dev Bid must be higher than current highest bid and sent with ETH
     */
    function bid() external payable {
        // Check if auction is still ongoing
        if (block.timestamp > s_auctionEndTime) {
            revert AuctionHouse__AuctionAlreadyEnded();
        }
        
        // Check if bid is high enough
        if (msg.value <= s_highestBid) {
            revert AuctionHouse__BidNotHighEnough();
        }
        
        // Refund the previous highest bidder if there is one
        if (s_highestBidder != address(0)) {
            // Transfer previous highest bid back to previous bidder
            payable(s_highestBidder).transfer(s_highestBid);
        }
        
        // Update highest bid and bidder
        s_highestBidder = msg.sender;
        s_highestBid = msg.value;
        
        emit NewHighestBid(msg.sender, msg.value);
    }
    
    /**
     * @notice End the auction and transfer funds to owner
     * @dev Can only be called after auction end time
     */
    function endAuction() external {
        // Check if auction time has passed
        if (block.timestamp < s_auctionEndTime) {
            revert AuctionHouse__AuctionNotYetEnded();
        }
        
        // Check if auction has already been ended
        if (s_auctionEnded) {
            revert AuctionHouse__AuctionEndAlreadyCalled();
        }
        
        // Mark auction as ended
        s_auctionEnded = true;
        
        emit AuctionEnded(s_highestBidder, s_highestBid);
        
        // Transfer the highest bid to the owner
        if (s_highestBid > 0) {
            payable(s_owner).transfer(s_highestBid);
        }
    }
    
    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Get the remaining time in the auction
     * @dev Returns 0 if auction has ended
     * @return The remaining time in seconds
     */
    function getRemainingTime() external view returns (uint256) {
        if (block.timestamp >= s_auctionEndTime) {
            return 0;
        }
        return s_auctionEndTime - block.timestamp;
    }
    
    /**
     * @notice Check if the auction is still active
     * @return True if auction is active, false otherwise
     */
    function isActive() external view returns (bool) {
        return block.timestamp < s_auctionEndTime && !s_auctionEnded;
    }
    
    /**
     * @notice Get the current auction status
     * @return highestBidder The address of the highest bidder
     * @return highestBid The current highest bid
     * @return timeRemaining Time remaining in seconds
     * @return ended Whether the auction has ended
     */
    function getAuctionStatus() external view returns (
        address highestBidder,
        uint256 highestBid,
        uint256 timeRemaining,
        bool ended
    ) {
        uint256 remaining = 0;
        if (block.timestamp < s_auctionEndTime) {
            remaining = s_auctionEndTime - block.timestamp;
        }
        
        return (s_highestBidder, s_highestBid, remaining, s_auctionEnded);
    }
}