// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/NFTCollection.sol";
import "../src/NFTMarketplace.sol";

contract MarketplaceTest is Test {
    NFTCollection nft;
    NFTMarketplace market;

    address owner = address(0xABCD);
    address seller = address(0xBEEF);
    address buyer = address(0xCAFE);
    address royaltyReceiver = address(0xD00D);

    function setUp() public {
        vm.prank(owner);
        nft = new NFTCollection("MyNFT", "MNFT", "ipfs://base/");

        vm.prank(owner);
        market = new NFTMarketplace(250); // 2.5% marketplace fee

        // owner mints token 1 to seller with per-token royalty 500 bps (5%)
        vm.prank(owner);
        uint256 tokenId = nft.mint(seller, 500);

        // set default royalty (optional)
        vm.prank(owner);
        nft.setDefaultRoyalty(royaltyReceiver, 200); // 2%
    }

    function testListAndBuyWithRoyalties() public {
        // seller approves marketplace
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        // list it for 1 ETH
        market.list(address(nft), 1, 1 ether);
        vm.stopPrank();

        // buyer buys
        vm.deal(buyer, 2 ether);

        uint256 sellerBefore = seller.balance;
        uint256 royaltyBefore = royaltyReceiver.balance;
        uint256 ownerBefore = owner.balance;

        vm.prank(buyer);
        market.buy{value: 1 ether}(address(nft), 1);

        // marketplace fee = 2.5% of 1 ETH = 0.025 ETH
        // token had per-token royalty 5% = 0.05 ETH -> paid to owner (because mint set to owner)
        // remaining to seller = 1 - 0.025 - 0.05 = 0.925 ETH

        // Note: we minted with royalty to owner in mint above for token-specific royalty, but also set default royalty to royaltyReceiver. Per-token royalty takes precedence.
        // Since mint set per-token royalty to owner (owner() from contract), royaltyReceiver (default) not used.
        // But in setUp we also set default royalty; for this test we calculate for per-token.

        // We check ownership changed
        assertEq(nft.ownerOf(1), buyer);

        // Check balances approximately (because of EVM integer arithmetic exactly)
        // seller should have increased by 0.925 ETH
        uint256 sellerAfter = seller.balance;
        uint256 royaltyAfter = owner.balance; // since per-token royalty receiver was owner
        uint256 ownerAfter = owner.balance;

        // Validate seller received expected amount:
        // Because owner got royalty, and owner got marketplace fee too, owner receives both. To assert funds, we compute totals:
        // Let's compute expected:
        uint256 feeAmount = (1 ether * 250) / 10000; // 0.025 ETH
        uint256 royaltyAmount = (1 ether * 500) / 10000; // 0.05 ETH
        uint256 expectedSellerGain = 1 ether - feeAmount - royaltyAmount;

        assertEq(sellerAfter - sellerBefore, expectedSellerGain);
        assertEq(owner.balance - ownerBefore, feeAmount + royaltyAmount);
    }

    function testCancelListing() public {
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.list(address(nft), 1, 0.5 ether);
        market.cancel(address(nft), 1);
        vm.stopPrank();

        (address lSeller, ) = vm.accesses(address(market), abi.encodeWithSignature("listings(address,uint256)", address(nft), 1)); // not used; just illustrate
        // ensure not listed
        (, ) = (lSeller, 0);
        // try to buy should revert
        vm.prank(buyer);
        vm.expectRevert();
        market.buy{value: 0.5 ether}(address(nft), 1);
    }
}
