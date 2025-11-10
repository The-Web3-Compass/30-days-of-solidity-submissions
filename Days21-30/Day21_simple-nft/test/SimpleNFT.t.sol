// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/SimpleNFT.sol";

contract SimpleNFTTest is Test {
    SimpleNFT nft;
    address owner = address(0xABCD);
    address user1 = address(0x1234);

    function setUp() public {
        nft = new SimpleNFT("MyNFT", "MNFT");
    }

    function testNameAndSymbol() public view{
        assertEq(nft.name(), "MyNFT");
        assertEq(nft.symbol(), "MNFT");
    }

    function testMintIncrementsBalance() public {
        nft.mint(owner, "ipfs://QmExample1");
        assertEq(nft.balanceOf(owner), 1);
        assertEq(nft.ownerOf(1), owner);
    }

    function testTransferNFT() public {
        nft.mint(owner, "ipfs://QmExample1");

        // Simulate owner calling transfer
        vm.prank(owner);
        nft.transferFrom(owner, user1, 1);

        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.balanceOf(owner), 0);
    }

    function testTokenURI() public {
        nft.mint(owner, "ipfs://QmMyMetaHash");
        string memory uri = nft.tokenURI(1);
        assertEq(uri, "ipfs://QmMyMetaHash");
    }

    function test_RevertWhen_TransferNotAuthorized() public {
        nft.mint(owner, "ipfs://QmExample1");
        
        // Expect the transaction to revert with "Not authorized"
        vm.expectRevert(bytes("Not authorized"));
        
        vm.prank(user1);
        nft.transferFrom(owner, user1, 1);
    }
}
