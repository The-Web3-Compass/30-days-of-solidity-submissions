// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract DigitalCollectibles is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIdCounter;

    // Card rarity levels
    enum Rarity { Common, Uncommon, Rare, Epic, Legendary }
    
    // NFT properties structure
    struct CardProperties {
        string name;
        Rarity rarity;
        string description;
        string element;  // e.g., Fire, Water, Earth
        uint256 attack;
        uint256 defense;
        uint256 serialNumber;
    }
    
    // Token ID to CardProperties mapping
    mapping(uint256 => CardProperties) private _cardProperties;
    
    // Events
    event CardMinted(
        address indexed owner,
        uint256 indexed tokenId,
        string name,
        Rarity rarity
    );

    constructor() ERC721("MythicCards", "MYTH") {}
    
    /**
     * @dev Mint a new collectible card (owner only)
     * @param to Recipient address
     * @param name Card name
     * @param rarityIndex Rarity level (0-4)
     * @param description Card description
     * @param element Card element type
     * @param attack Attack power
     * @param defense Defense power
     */
    function mintCard(
        address to,
        string memory name,
        uint8 rarityIndex,
        string memory description,
        string memory element,
        uint256 attack,
        uint256 defense
    ) external onlyOwner {
        require(rarityIndex <= uint8(Rarity.Legendary), "Invalid rarity");
        
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        
        _safeMint(to, tokenId);
        
        _cardProperties[tokenId] = CardProperties({
            name: name,
            rarity: Rarity(rarityIndex),
            description: description,
            element: element,
            attack: attack,
            defense: defense,
            serialNumber: tokenId
        });
        
        emit CardMinted(to, tokenId, name, Rarity(rarityIndex));
    }
    
    /**
     * @dev Generate on-chain SVG artwork for the card
     * @param tokenId Token ID
     */
    function generateSVG(uint256 tokenId) internal view returns (string memory) {
        CardProperties memory card = _cardProperties[tokenId];
        
        string memory rarityColor;
        if (card.rarity == Rarity.Common) rarityColor = "#9E9E9E";
        else if (card.rarity == Rarity.Uncommon) rarityColor = "#4CAF50";
        else if (card.rarity == Rarity.Rare) rarityColor = "#2196F3";
        else if (card.rarity == Rarity.Epic) rarityColor = "#9C27B0";
        else rarityColor = "#FF9800"; // Legendary
        
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="600" viewBox="0 0 400 600">',
            '<rect width="400" height="600" fill="#1A1A2E" rx="20" ry="20"/>',
            '<rect x="20" y="20" width="360" height="560" fill="#16213E" rx="15" ry="15"/>',
            
            // Card title
            '<text x="200" y="70" font-family="Arial" font-weight="bold" font-size="28" fill="',
            rarityColor,
            '" text-anchor="middle">', card.name, '</text>',
            
            // Element type
            '<text x="200" y="110" font-family="Arial" font-size="20" fill="#FFFFFF" text-anchor="middle">',
            card.element, ' Element</text>',
            
            // Stats
            '<rect x="50" y="150" width="300" height="40" fill="', rarityColor, '" rx="10" ry="10"/>',
            '<text x="200" y="180" font-family="Arial" font-size="22" fill="#FFFFFF" text-anchor="middle">',
            'ATK: ', card.attack.toString(), ' | DEF: ', card.defense.toString(), '</text>',
            
            // Description
            '<rect x="50" y="220" width="300" height="200" fill="#0F3460" rx="10" ry="10"/>',
            '<foreignObject x="60" y="230" width="280" height="180">',
            '<div xmlns="http://www.w3.org/1999/xhtml" style="color:#FFFFFF; font-family:Arial; font-size:14px; text-align:center">',
            card.description, '</div></foreignObject>',
            
            // Rarity
            '<rect x="50" y="450" width="300" height="40" fill="', rarityColor, '" rx="10" ry="10"/>',
            '<text x="200" y="480" font-family="Arial" font-size="22" fill="#FFFFFF" text-anchor="middle">',
            getRarityString(card.rarity), '</text>',
            
            // Serial number
            '<text x="360" y="580" font-family="Arial" font-size="16" fill="#CCCCCC">#',
            card.serialNumber.toString(), '</text>',
            '</svg>'
        ));
    }
    
    /**
     * @dev Generate complete token metadata including SVG
     * @param tokenId Token ID
     */
    function tokenURI(uint256 tokenId) 
        public 
        view 
        override 
        returns (string memory) 
    {
        require(_exists(tokenId), "Token doesn't exist");
        
        CardProperties memory card = _cardProperties[tokenId];
        string memory svg = generateSVG(tokenId);
        string memory json = Base64.encode(abi.encodePacked(
            '{"name": "', card.name, '",',
            '"description": "', card.description, '",',
            '"attributes": [',
            '{"trait_type": "Rarity", "value": "', getRarityString(card.rarity), '"},',
            '{"trait_type": "Element", "value": "', card.element, '"},',
            '{"trait_type": "Attack", "value": ', card.attack.toString(), '},',
            '{"trait_type": "Defense", "value": ', card.defense.toString(), '},',
            '{"trait_type": "Serial", "value": ', card.serialNumber.toString(), '}',
            '],',
            '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'
        ));
        
        return string(abi.encodePacked(
            "data:application/json;base64,", json
        ));
    }
    
    /**
     * @dev Convert rarity enum to string
     * @param rarity Rarity level
     */
    function getRarityString(Rarity rarity) internal pure returns (string memory) {
        if (rarity == Rarity.Common) return "Common";
        if (rarity == Rarity.Uncommon) return "Uncommon";
        if (rarity == Rarity.Rare) return "Rare";
        if (rarity == Rarity.Epic) return "Epic";
        return "Legendary";
    }
    
    /**
     * @dev Get card properties by token ID
     * @param tokenId Token ID
     */
    function getCardProperties(uint256 tokenId) external view returns (
        string memory name,
        string memory rarity,
        string memory description,
        string memory element,
        uint256 attack,
        uint256 defense,
        uint256 serialNumber
    ) {
        require(_exists(tokenId), "Token doesn't exist");
        CardProperties memory card = _cardProperties[tokenId];
        return (
            card.name,
            getRarityString(card.rarity),
            card.description,
            card.element,
            card.attack,
            card.defense,
            card.serialNumber
        );
    }
    
    /**
     * @dev Get total number of minted cards
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }
}