/**
 * @title SimpleNFT
 * @dev 数字收藏品
 * 功能点：
 * 1. minting NFTs  铸造 NFT
 * 2. metadata storage  元数据存储
 * 3. ntf本身是10个限量版本的钻石像素风图片，钻石颜色随机生成
 * 通过实施 ERC721 标准和存储元数据来制作独特的数字项目
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title SimpleNFT
 * @dev 实现ERC721标准的限量版钻石像素风NFT
 */
contract SimpleNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    // 最大供应量
    uint256 public constant MAX_SUPPLY = 10;
    
    // 铸造价格
    uint256 public mintPrice = 0.01 ether;
    
    // 钻石颜色
    struct DiamondColor {
        uint8 r; // 红色 (0-255)
        uint8 g; // 绿色 (0-255)
        uint8 b; // 蓝色 (0-255)
    }
    
    // 钻石颜色映射
    mapping(uint256 => DiamondColor) private diamondColors;
    
    // 基础SVG
    string private baseSvg = '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" viewBox="0 0 350 350"><rect width="100%" height="100%" fill="black" />';
    
    // 事件
    event DiamondMinted(address indexed to, uint256 indexed tokenId, DiamondColor color);
    
    /**
     * @dev 构造函数
     */
    constructor() ERC721("PixelDiamond", "PDMD") Ownable(msg.sender) {}
    
    /**
     * @dev 铸造NFT
     */
    function mint() external payable {
        uint256 supply = totalSupply();
        require(supply < MAX_SUPPLY, "All diamonds have been minted");
        require(msg.value >= mintPrice, "Insufficient payment");
        
        // 生成随机颜色
        DiamondColor memory color = generateRandomColor(supply, msg.sender);
        
        // 存储颜色
        diamondColors[supply + 1] = color;
        
        // 铸造NFT
        _safeMint(msg.sender, supply + 1);
        
        emit DiamondMinted(msg.sender, supply + 1, color);
        
        // 如果支付金额超过铸造价格，退还多余的ETH
        if (msg.value > mintPrice) {
            payable(msg.sender).transfer(msg.value - mintPrice);
        }
    }
    
    /**
     * @dev 生成随机颜色
     * @param _tokenId 代币ID
     * @param _sender 发送者地址
     * @return 钻石颜色
     */
    function generateRandomColor(uint256 _tokenId, address _sender) internal view returns (DiamondColor memory) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, _sender, _tokenId)));
        
        return DiamondColor({
            r: uint8(rand % 256),
            g: uint8((rand >> 8) % 256),
            b: uint8((rand >> 16) % 256)
        });
    }
    
    /**
     * @dev 检查代币是否存在
     * @param _tokenId 代币ID
     * @return 是否存在
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _ownerOf(_tokenId) != address(0);
    }
    
    /**
     * @dev 获取钻石颜色
     * @param _tokenId 代币ID
     * @return 钻石颜色
     */
    function getDiamondColor(uint256 _tokenId) public view returns (DiamondColor memory) {
        require(exists(_tokenId), "Token does not exist");
        return diamondColors[_tokenId];
    }
    
    /**
     * @dev 获取钻石颜色的十六进制表示
     * @param _tokenId 代币ID
     * @return 十六进制颜色代码
     */
    function getColorHex(uint256 _tokenId) public view returns (string memory) {
        DiamondColor memory color = getDiamondColor(_tokenId);
        
        return string(abi.encodePacked(
            "#",
            toHex(color.r),
            toHex(color.g),
            toHex(color.b)
        ));
    }
    
    /**
     * @dev 将uint8转换为十六进制字符串
     * @param _value 值
     * @return 十六进制字符串
     */
    function toHex(uint8 _value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789ABCDEF";
        bytes memory str = new bytes(2);
        str[0] = alphabet[_value / 16];
        str[1] = alphabet[_value % 16];
        return string(str);
    }
    
    /**
     * @dev 生成钻石SVG
     * @param _tokenId 代币ID
     * @return SVG字符串
     */
    function generateDiamondSVG(uint256 _tokenId) public view returns (string memory) {
        string memory colorHex = getColorHex(_tokenId);
        
        string memory diamond = string(abi.encodePacked(
            '<polygon points="175,50 250,175 175,300 100,175" fill="',
            colorHex,
            '" stroke="white" stroke-width="2" />',
            '<text x="175" y="330" font-family="Arial" font-size="20" fill="white" text-anchor="middle">Diamond #',
            _tokenId.toString(),
            '</text>'
        ));
        
        return string(abi.encodePacked(
            baseSvg,
            diamond,
            '</svg>'
        ));
    }
    
    /**
     * @dev 生成代币URI
     * @param _tokenId 代币ID
     * @return URI字符串
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(exists(_tokenId), "Token does not exist");
        
        DiamondColor memory color = getDiamondColor(_tokenId);
        string memory colorHex = getColorHex(_tokenId);
        string memory svg = generateDiamondSVG(_tokenId);
        string memory encodedSvg = Base64.encode(bytes(svg));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Pixel Diamond #',
            _tokenId.toString(),
            '", "description": "A limited edition pixel art diamond with a unique color.", "attributes": [{"trait_type": "Color", "value": "',
            colorHex,
            '"}, {"trait_type": "Red", "value": ',
            uint256(color.r).toString(),
            '}, {"trait_type": "Green", "value": ',
            uint256(color.g).toString(),
            '}, {"trait_type": "Blue", "value": ',
            uint256(color.b).toString(),
            '}], "image": "data:image/svg+xml;base64,',
            encodedSvg,
            '"}'
        ))));
        
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
    
    /**
     * @dev 设置铸造价格
     * @param _mintPrice 新的铸造价格
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }
    
    /**
     * @dev 提取合约余额
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(owner()).transfer(balance);
    }
}

