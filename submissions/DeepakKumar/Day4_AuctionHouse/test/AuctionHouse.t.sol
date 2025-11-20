// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/AuctionHouse.sol";

contract AuctionHouseTest is Test {
    AuctionHouse auction;
    address bidder1 = address(0x1);
    address bidder2 = address(0x2);

    function setUp() public {
        auction = new AuctionHouse(60); // 60 seconds
    }

    function testBiddingProcess() public {
        vm.deal(bidder1, 10 ether);
        vm.deal(bidder2, 20 ether);

        vm.prank(bidder1);
        auction.bid{value: 1 ether}();

        vm.prank(bidder2);
        auction.bid{value: 2 ether}();

        (bool success,) = bidder1.call{value: auction.bids(bidder1)}("");
        assertTrue(success);
    }
}
