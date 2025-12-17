// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 1. 导入OpenZeppelin提供的、经过安全审计的标准合约
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SimpleNFT
 * @dev 一个遵循行业最佳实践的ERC721合约，继承自OpenZeppelin。
 */
contract SimpleNFT is ERC721, ERC721URIStorage, Ownable {

    // 用于生成唯一Token ID的计数器
    uint256 private _nextTokenId;

    /**
     * @dev 构造函数，设置NFT的名称、符号以及初始所有者。
     */
    constructor(address initialOwner)
        ERC721("Simple NFT", "SNFT") // 设置NFT系列的名称和符号
        Ownable(initialOwner)       // 设置合约的初始所有者
    {}

    /**
     * @dev 铸造一个新的NFT并将其分配给指定接收者。
     * 只有合约所有者才能调用此函数。
     * @param to 接收新NFT的地址。
     * @param uri 与此NFT关联的元数据URI。
     */
    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = ++_nextTokenId;
        // 调用OpenZeppelin提供的安全铸造函数
        _safeMint(to, tokenId);
        // 调用OpenZeppelin提供的函数来设置元数据URI
        _setTokenURI(tokenId, uri);
    }

    // --- 以下所有核心ERC721功能都已自动继承，无需手动编写 ---
    //
    // function ownerOf(uint256 tokenId) ...
    // function balanceOf(address owner) ...
    // function transferFrom(address from, address to, uint256 tokenId) ...
    // function approve(address to, uint256 tokenId) ...
    // ...以及其他所有标准功能。

    /**
     * @dev 重写tokenURI函数以使用ERC721URIStorage的功能。
     * 这是为了让每个代币可以有独立的URI。
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev 重写supportsInterface函数以解决多重继承中的冲突。
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
