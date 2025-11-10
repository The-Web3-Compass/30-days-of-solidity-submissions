// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SimpleNFT is ERC721 {
    uint256 public nextId;

    constructor() ERC721("TestNFT", "TNFT") {}

    function mint() external {
        _safeMint(msg.sender, nextId);
        nextId++;
    }
}
