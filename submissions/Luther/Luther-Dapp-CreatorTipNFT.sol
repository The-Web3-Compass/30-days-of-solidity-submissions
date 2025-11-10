//
// CreatorTipNFT - NFT 打赏系统
// 
// 项目简介：
// CreatorTipNFT 是一个基于 ERC721 标准的去中心化打赏合约。
// 创作者可以创建属于自己的 NFT，粉丝通过向 NFT 发送 ETH 的方式进行打赏，
// 创作者可在合约中提取累计的小费收益，实现公开透明的支持系统。
//
// 合约说明：
// - 每个 NFT 对应一位创作者身份
// - 用户可以调用 tip() 对任意 NFT 打赏 ETH
// - 创作者调用 withdraw() 可提取收到的打赏金额
// - 所有打赏记录都在链上公开可查

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CreatorTipNFT is ERC721, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct CreatorInfo {
        address creator;
        uint256 totalTips;
        uint256 tipCount;
    }

    mapping(uint256 => CreatorInfo) public creatorData;
    mapping(address => uint256) public totalReceived;

    event NFTCreated(address indexed creator, uint256 indexed tokenId);
    event Tipped(address indexed from, uint256 indexed tokenId, uint256 amount);
    event Withdrawn(address indexed creator, uint256 amount);

    constructor() ERC721("Creator Tip NFT", "CTN") {}

    function createNFT() external returns (uint256) {
        _tokenIds.increment();
        uint256 newId = _tokenIds.current();
        _safeMint(msg.sender, newId);
        creatorData[newId] = CreatorInfo(msg.sender, 0, 0);
        emit NFTCreated(msg.sender, newId);
        return newId;
    }

    function tip(uint256 tokenId) external payable nonReentrant {
        require(_ownerOf(tokenId) != address(0), "NFT does not exist");
        require(msg.value > 0, "Tip must be > 0");
        CreatorInfo storage info = creatorData[tokenId];
        info.totalTips += msg.value;
        info.tipCount += 1;
        totalReceived[info.creator] += msg.value;
        emit Tipped(msg.sender, tokenId, msg.value);
    }

    function withdraw(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        uint256 amount = creatorData[tokenId].totalTips;
        require(amount > 0, "No tips");
        creatorData[tokenId].totalTips = 0;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getCreatorTips(uint256 tokenId) external view returns (uint256, uint256) {
        require(_ownerOf(tokenId) != address(0), "NFT does not exist");
        CreatorInfo memory info = creatorData[tokenId];
        return (info.totalTips, info.tipCount);
    }

    function getTotalReceived(address creator) external view returns (uint256) {
        return totalReceived[creator];
    }

    function getAllNFTs() external view returns (uint256[] memory) {
        uint256 total = _tokenIds.current();
        uint256[] memory ids = new uint256[](total);
        for (uint256 i = 0; i < total; i++) {
            ids[i] = i + 1;
        }
        return ids;
    }
}
