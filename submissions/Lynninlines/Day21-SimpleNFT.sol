// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleNFT {
    string public name;
    string public symbol;
    uint256 public tokenCounter;
    
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => string) private _tokenMetadataURIs;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Minted(address indexed to, uint256 tokenId, string metadataURI);
    
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        tokenCounter = 0;
    }
    
    function mint(string memory metadataURI) public {
        uint256 newTokenId = tokenCounter;
        tokenCounter += 1;
        
        _owners[newTokenId] = msg.sender;
        _balances[msg.sender] += 1;
        _tokenMetadataURIs[newTokenId] = metadataURI;
        
        emit Transfer(address(0), msg.sender, newTokenId);
        emit Minted(msg.sender, newTokenId, metadataURI);
    }
    
    function ownerOf(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return _owners[tokenId];
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Zero address query");
        return _balances[owner];
    }
    
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return _tokenMetadataURIs[tokenId];
    }
    
    function transfer(address to, uint256 tokenId) public {
        require(_owners[tokenId] == msg.sender, "Not token owner");
        require(to != address(0), "Transfer to zero address");
        
        _balances[msg.sender] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        
        emit Transfer(msg.sender, to, tokenId);
    }
    
    function getAllTokens(address owner) public view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < tokenCounter; i++) {
            if (_owners[i] == owner) {
                count++;
            }
        }
        
        uint256[] memory tokens = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < tokenCounter; i++) {
            if (_owners[i] == owner) {
                tokens[index] = i;
                index++;
            }
        }
        return tokens;
    }
}
