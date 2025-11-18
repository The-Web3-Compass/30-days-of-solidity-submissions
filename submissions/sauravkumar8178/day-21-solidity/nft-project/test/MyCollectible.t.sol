// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/MyCollectible.sol";

contract MyCollectibleTest is Test {
    MyCollectible nft;
    address owner = address(this);
    address user = address(0xBEEF);

    function setUp() public {
        nft = new MyCollectible();
    }

    function testMintTo() public {
        string memory uri = "ipfs://test-metadata";
        nft.mintTo(user, uri);

        assertEq(nft.ownerOf(1), user);
        assertEq(nft.totalMinted(), 1);
        assertEq(nft.tokenURI(1), uri);
    }
}
