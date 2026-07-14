// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@4.9.5/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.9.5/access/Ownable.sol";

contract PetIdentity is ERC721, Ownable {

    uint256 public nextPetId = 1119;

    struct PetInfo {
        string name;
        string species;
        string breed;
        uint64 birthday;
        string traits;
        string city;
        uint64 createdAt;
    }

    mapping(uint256 => PetInfo) public pets;
    mapping(uint256 => string) private _tokenURIs;

    event PetMinted(uint256 indexed petId, address indexed owner);
    event PetUpdated(uint256 indexed petId);

    constructor() ERC721("PetIdentity", "PETID") Ownable() {}

    /**
     * 拆开参数的 mintPet
     */
    function mintPet(
        string calldata name,
        string calldata species,
        string calldata breed,
        uint64 birthday,
        string calldata traits,
        string calldata city,
        string calldata tokenURI_
    ) external returns (uint256) {

        uint256 petId = nextPetId++;

        _safeMint(msg.sender, petId);

        pets[petId] = PetInfo(
            name,
            species,
            breed,
            birthday,
            traits,
            city,
            uint64(block.timestamp)
        );

        _tokenURIs[petId] = tokenURI_;

        emit PetMinted(petId, msg.sender);
        return petId;
    }

    /**
     * 允许 NFT 持有人更新信息
     */
    function updatePetInfo(
        uint256 petId,
        string calldata name,
        string calldata species,
        string calldata breed,
        uint64 birthday,
        string calldata traits,
        string calldata city
    ) external {
        require(ownerOf(petId) == msg.sender, "Not owner");

        pets[petId] = PetInfo(
            name,
            species,
            breed,
            birthday,
            traits,
            city,
            pets[petId].createdAt
        );

        emit PetUpdated(petId);
    }

    /**
     * 修改 tokenURI（支持 owner、授权者、平台管理员）
     */
    function setTokenURI(uint256 petId, string calldata tokenURI_) external {
        require(
            msg.sender == ownerOf(petId) ||
            msg.sender == owner() ||
            getApproved(petId) == msg.sender ||
            isApprovedForAll(ownerOf(petId), msg.sender),
            "Not authorized"
        );

        _tokenURIs[petId] = tokenURI_;
        emit PetUpdated(petId);
    }

    /**
     * @dev 返回 tokenURI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "No token");
        return _tokenURIs[tokenId];
    }
}
