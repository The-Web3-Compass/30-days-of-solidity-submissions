// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title PetMoments
 * @notice 为已经存在的 ERC721 宠物 NFT 增加“时刻”功能（照片 + 描述 + 时间戳）
 */
contract PetMoments is ERC165 {
    /// 单条宠物时刻结构
    struct Moment {
        string imageURI;
        string description;
        uint64 timestamp;
    }

    /// 外部 NFT 合约
    IERC721 public immutable petNft;

    /// 存储：tokenId → Moments[]
    mapping(uint256 => Moment[]) private _moments;

    /// 添加时刻事件
    event MomentAdded(
        uint256 indexed tokenId,
        uint256 indexed index,
        address indexed uploader,
        string imageURI,
        string description,
        uint64 timestamp
    );

    /// 构造函数：传入你已部署的 NFT 合约地址
    constructor(address _petNft) {
        require(_petNft != address(0), "Invalid NFT address");
        petNft = IERC721(_petNft);
    }

    /// 校验是否为 owner 或授权者
    function _isApprovedOrOwner(uint256 tokenId) internal view returns (bool) {
        address owner = petNft.ownerOf(tokenId);

        if (msg.sender == owner) return true;
        if (petNft.getApproved(tokenId) == msg.sender) return true;
        if (petNft.isApprovedForAll(owner, msg.sender)) return true;

        return false;
    }

    /// 添加时刻
    function addMoment(
        uint256 tokenId,
        string calldata imageURI,
        string calldata description
    ) external {
        require(_isApprovedOrOwner(tokenId), "Not owner nor approved");
        require(bytes(imageURI).length > 0, "Image URI cannot be empty");

        Moment memory m = Moment({
            imageURI: imageURI,
            description: description,
            timestamp: uint64(block.timestamp)
        });

        _moments[tokenId].push(m);
        uint256 index = _moments[tokenId].length - 1;

        emit MomentAdded(
            tokenId,
            index,
            msg.sender,
            imageURI,
            description,
            m.timestamp
        );
    }

    /// 获取时刻数量
    function getMomentsCount(uint256 tokenId) external view returns (uint256) {
        return _moments[tokenId].length;
    }

    /// 获取某条时刻
    function getMoment(uint256 tokenId, uint256 index)
        external
        view
        returns (string memory, string memory, uint64)
    {
        require(index < _moments[tokenId].length, "Index out of range");

        Moment storage m = _moments[tokenId][index];
        return (m.imageURI, m.description, m.timestamp);
    }

    /// 获取全部时刻（前端用）
    function getAllMoments(uint256 tokenId)
        external
        view
        returns (Moment[] memory)
    {
        return _moments[tokenId];
    }

    /// ERC165 兼容
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
