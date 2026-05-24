// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleNFT {

    string public name = "SimpleNFT";
    string public symbol = "SNFT";

    uint256 private tokenCounter;

    // Token owner mapping
    mapping(uint256 => address) private owners;

    // Owner balance mapping
    mapping(address => uint256) private balances;

    // Token metadata (URI)
    mapping(uint256 => string) private tokenURIs;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /*
     * Mint NFT
     */
    function mint(string memory _tokenURI) public {

        uint256 tokenId = tokenCounter;

        owners[tokenId] = msg.sender;
        balances[msg.sender] += 1;
        tokenURIs[tokenId] = _tokenURI;

        emit Transfer(address(0), msg.sender, tokenId);

        tokenCounter++;
    }

    /*
     * Get owner of NFT
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        require(owners[tokenId] != address(0), "Token does not exist");
        return owners[tokenId];
    }

    /*
     * Get balance of user
     */
    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    /*
     * Get token metadata
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(owners[tokenId] != address(0), "Token does not exist");
        return tokenURIs[tokenId];
    }

    /*
     * Transfer NFT
     */
    function transfer(address to, uint256 tokenId) public {

        require(ownerOf(tokenId) == msg.sender, "Not owner");

        owners[tokenId] = to;
        balances[msg.sender] -= 1;
        balances[to] += 1;

        emit Transfer(msg.sender, to, tokenId);
    }
}