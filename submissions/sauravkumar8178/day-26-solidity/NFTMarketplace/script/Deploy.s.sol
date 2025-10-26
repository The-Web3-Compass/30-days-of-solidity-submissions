// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/NFTCollection.sol";
import "../src/NFTMarketplace.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        NFTCollection nft = new NFTCollection("MyNFT", "MNFT", "ipfs://base/");
        NFTMarketplace market = new NFTMarketplace(250); // 2.5%

        // optionally set default royalty example:
        nft.setDefaultRoyalty(msg.sender, 200);

        vm.stopBroadcast();
    }
}
