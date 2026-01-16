// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title SimpleNft
 * @dev Create your own digital collectibles (NFTs)!
 * You'll learn how to make unique digital items by implementing the ERC721 standard and storing metadata.
 * It's like creating digital trading cards, demonstrating NFT creation.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 21
 */
contract SimpleNft is ERC721 {
    constructor() ERC721("BguizNft", "BGZ") {
    }

    function _baseURI() internal override pure virtual returns (string memory) {
        return "https://my.domain.example/BguizNft/";
    }
}
