//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title simple NFT
 * @author Eric (https://github.com/0xxEric)
 * @notice simple NFT
 * @custom:project 30-days-of-solidity-submissions: Day21
 */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Simple ERC721 with per-token ERC2981 royalties on mint
contract MyNFT is ERC721URIStorage, ERC2981, AccessControl {
    uint256 public nextTokenId;
    // address public admin;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Base URI (e.g., "https://api.mynft.io/metadata/")
    string private baseURI_;

    //role assignment
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_)  {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

/* ---------------------- Role Management ---------------------- */
    function grantMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, account);
    }

    function revokeMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, account);
    }

     function grantAdminRole(address newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
    }

/* ---------------------- Base URI Management ---------------------- */
    /// @notice Set global base URI for all tokens (e.g. https://api.mynft.io/metadata/)
    function setBaseURI(string memory newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI_ = newBaseURI;
    }

    /// @notice Get current base URI
    function baseURI() public view returns (string memory) {
        return baseURI_;
    }

/* ---------------------- Minting ---------------------- */
    /// @notice Mint and set tokenURI and royalty (bps: parts per 10k)
    function mint(
        address to,
        string calldata tokenURI_,
        address royaltyReceiver,
        uint96 royaltyBps
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 tid = nextTokenId++;
        _safeMint(to, tid);
        _setTokenURI(tid, tokenURI_);



        if (royaltyReceiver != address(0) && royaltyBps > 0) {
            // set per-token royalty
            _setTokenRoyalty(tid, royaltyReceiver, royaltyBps); // TokenRoyalty is defined in ERC2981
        }
        return tid;
    }

    // Admin: set default royalty (optional)
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }

    // ERC165 support
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721URIStorage, ERC2981,AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

/* ---------------------- URI Logic Override ---------------------- */
    /// @dev Override tokenURI to combine baseURI + tokenId if no custom URI is set
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721URIStorage)
        returns (string memory)
    {
        string memory customURI = super.tokenURI(tokenId);
        string memory base = baseURI();

        // If custom URI is set, return it; otherwise return baseURI + tokenId
        if (bytes(customURI).length > 0) {
            return customURI;
        } else if (bytes(base).length > 0) {
            return string(abi.encodePacked(base, _toString(tokenId), ".json"));
        } else {
            return "";
        }
    }
}
