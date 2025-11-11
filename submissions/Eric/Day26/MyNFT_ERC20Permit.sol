// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "./IERC4494.sol";
// import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

/// @title Simple ERC721 with per-token ERC2981 royalties and ERC-4494-style permit
contract MyNFT is ERC721URIStorage, ERC2981, AccessControl, EIP712,IERC4494 {
    using ECDSA for bytes32;

    uint256 public nextTokenId;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // per-token nonces for permit (EIP-4494 style)
    mapping(uint256 => uint256) public nonces;

    // EIP-712 typehash for permit
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
        EIP712(name_, "1") // domain name version 1
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    // existing role management functions...
    function grantMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, account);
    }
    function revokeMinterRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, account);
    }
    function grantAdminRole(address newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
    }

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
            _setTokenRoyalty(tid, royaltyReceiver, royaltyBps);
        }
        return tid;
    }

    // ERC-4494 style permit: allows owner to approve spender for tokenId via signature
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        bytes calldata signature
    ) external {
        require(block.timestamp <= deadline, "Permit expired");
        address owner = ownerOf(tokenId);
        uint256 nonce = nonces[tokenId];

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, spender, tokenId, nonce, deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signature);
        require(signer == owner, "Invalid permit signature");

        nonces[tokenId] = nonce + 1; // increment nonce to prevent replay
        _approve(spender, tokenId,owner);
    }


    // Admin: set default royalty (optional)
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    function deleteDefaultRoyalty() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }

    // ERC165 support
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721URIStorage, ERC2981, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function get_nonces(uint256 tokenId) public view returns (uint256) {
    return nonces[tokenId];
}

function DOMAIN_SEPARATOR() public view returns (bytes32) {
    return _domainSeparatorV4(); // 如果你继承了 OZ 的 EIP712
}

}
