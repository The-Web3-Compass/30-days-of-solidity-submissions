// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title  SimpleNFT — ERC-721 from Scratch
/// @author rainwaters11 — Day 26: The NFT Standard
/// @notice A fully hand-rolled ERC-721 implementation.
///         Rather than inheriting OpenZeppelin's ERC721.sol, every storage
///         slot, every check, and every event is implemented here so you can
///         see exactly what makes an NFT tick.
///
/// @dev    THE FOUR CORE MAPPINGS
///         ┌──────────────────────────────────────────────────────────────┐
///         │ _owners          tokenId  → owner address                    │
///         │ _balances        owner    → how many tokens they hold        │
///         │ _tokenApprovals  tokenId  → approved operator for that token │
///         │ _operatorApprovals owner → operator → approved for ALL tokens│
///         └──────────────────────────────────────────────────────────────┘
///
///         THE MINT FLOW
///         mint() → _mint() → updates _owners + _balances → emits Transfer
///
///         THE SAFE TRANSFER SECRET ("ping the contract first")
///         safeTransferFrom() → _transfer() → _checkOnERC721Received()
///           If recipient is a contract, we call onERC721Received() on it.
///           If it doesn't respond with the magic selector, we revert.
///           This prevents NFTs from becoming permanently locked in contracts
///           that have no way to move them (e.g., blind token custodians).
///
///         THE METADATA HOOK
///         tokenURI() returns: baseURI + tokenId
///         e.g. "ipfs://QmYourCollectionHash/1"
///         Each token ID maps to a unique JSON file on IPFS describing
///         its name, description, and image.
///
///         MISTICOIN-CORE USE CASES
///         • Mint a "Crochet Chain Founding Member" badge NFT.
///         • Issue NFT receipts for CropInsurance (Day 18) payouts.
///         • Gate access to DAO votes (Day 28) to NFT holders.
contract SimpleNFT is IERC721Metadata, Ownable {
    using Strings for uint256;

    // ─── Token metadata ───────────────────────────────────────────────────────

    /// @inheritdoc IERC721Metadata
    string public name;

    /// @inheritdoc IERC721Metadata
    string public symbol;

    /// @notice IPFS base URI — e.g. "ipfs://QmYourCollectionHash/"
    ///         tokenURI(1) → "ipfs://QmYourCollectionHash/1"
    string public baseURI;

    // ─── Counter ──────────────────────────────────────────────────────────────

    /// @notice Monotonically increasing token ID counter.
    ///         Starts at 1 (token 0 is reserved as the "null" check sentinel).
    uint256 public nextTokenId;

    // ─── Core ERC-721 storage ─────────────────────────────────────────────────

    /// @dev tokenId → owner address.
    ///      The single source of truth for ownership.  If _owners[id] == address(0)
    ///      the token either hasn't been minted or has been burned.
    mapping(uint256 => address) private _owners;

    /// @dev owner → number of tokens held.
    ///      Updated atomically with _owners so the two never disagree.
    mapping(address => uint256) private _balances;

    /// @dev tokenId → address approved to transfer *this specific token*.
    ///      Cleared on every transfer.
    mapping(uint256 => address) private _tokenApprovals;

    /// @dev owner → operator → approved for ALL of owner's tokens.
    ///      Used by marketplaces (OpenSea, Blur) so you approve once and they
    ///      can list/sell any of your NFTs without per-token approvals.
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // ─── Events (re-declared for clarity — already in IERC721) ───────────────

    // Transfer, Approval, ApprovalForAll are inherited from IERC721.

    // ─── Custom Errors ────────────────────────────────────────────────────────

    error NotMinted(uint256 tokenId);
    error ZeroAddress();
    error NotOwnerOrApproved();
    error TransferToSelf();
    error SafeTransferRejected(address to);
    error AlreadyMinted(uint256 tokenId);
    error MaxSupplyReached();
    error NotOwner(uint256 tokenId);

    // ─── Constructor ──────────────────────────────────────────────────────────

    /// @param _name     Collection name, e.g. "MistyCoin Founding Members".
    /// @param _symbol   Ticker symbol, e.g. "MCFM".
    /// @param _baseURI  IPFS base URI, e.g. "ipfs://QmYourCollectionHash/".
    /// @param _owner    Initial contract owner (can mint and set base URI).
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _owner
    ) Ownable(_owner) {
        name     = _name;
        symbol   = _symbol;
        baseURI  = _baseURI;
        nextTokenId = 1; // start at token #1
    }

    // ─── ERC-165 ──────────────────────────────────────────────────────────────

    /// @notice Signals which interfaces this contract supports.
    ///         Marketplaces call this to confirm we are a real ERC-721.
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId         ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    // ─── Mint ─────────────────────────────────────────────────────────────────

    /// @notice Owner-only mint — issues the next token to `to`.
    ///
    /// @dev    MINT FLOW:
    ///         1. Validate recipient (not zero address).
    ///         2. Increment nextTokenId (pre-mint so token IDs start at 1).
    ///         3. _owners[tokenId] = to      ← ownership recorded.
    ///         4. _balances[to]    += 1      ← balance incremented.
    ///         5. emit Transfer(address(0), to, tokenId).
    ///
    /// @param to  Recipient of the newly minted NFT.
    /// @return tokenId  The ID of the freshly minted token.
    function mint(address to) external onlyOwner returns (uint256 tokenId) {
        if (to == address(0)) revert ZeroAddress();

        tokenId = nextTokenId;
        nextTokenId++;

        _mint(to, tokenId);
    }

    /// @notice Batch-mint `count` tokens to `to` (owner only).
    function batchMint(address to, uint256 count) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();

        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = nextTokenId;
            nextTokenId++;
            _mint(to, tokenId);
        }
    }

    // ─── Internal: _mint ──────────────────────────────────────────────────────

    /// @dev Core mint primitive.  Called by public mint functions after
    ///      argument validation.
    ///
    ///      KEY: _owners and _balances are BOTH updated before the event fires.
    ///      This matches the ERC-721 spec which requires Transfer to be emitted
    ///      after state is consistent.
    function _mint(address to, uint256 tokenId) internal {
        // Guard: token must not already exist.
        if (_owners[tokenId] != address(0)) revert AlreadyMinted(tokenId);

        // ── EFFECT 1: record ownership ────────────────────────────────────────
        _owners[tokenId] = to;

        // ── EFFECT 2: increment balance ───────────────────────────────────────
        _balances[to] += 1;

        // ── INTERACTION: emit the canonical ERC-721 mint event ────────────────
        //    from = address(0) signals "newly minted" to indexers/marketplaces.
        emit Transfer(address(0), to, tokenId);
    }

    // ─── Transfer ─────────────────────────────────────────────────────────────

    /// @inheritdoc IERC721
    function transferFrom(address from, address to, uint256 tokenId)
        external
        override
    {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotOwnerOrApproved();
        _transfer(from, to, tokenId);
    }

    /// @inheritdoc IERC721
    /// @dev safeTransferFrom with no extra data.
    function safeTransferFrom(address from, address to, uint256 tokenId)
        external
        override
    {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @inheritdoc IERC721
    /// @dev THE SAFE TRANSFER SECRET:
    ///      After _transfer(), if `to` is a contract we call
    ///      onERC721Received() on it.  If the return value is not the magic
    ///      selector (0x150b7a02) we revert, keeping the NFT safe in the
    ///      sender's wallet rather than locking it in an incompatible contract.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotOwnerOrApproved();
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    // ─── Internal: _transfer ──────────────────────────────────────────────────

    /// @dev Core transfer primitive.  Updates _owners and _balances atomically.
    ///
    ///      CEI ORDER:
    ///      CHECKS     — token exists, from is current owner, to != address(0).
    ///      EFFECTS    — clear approval, update _owners, update _balances.
    ///      INTERACTIONS — emit Transfer event.
    function _transfer(address from, address to, uint256 tokenId) internal {

        // ── CHECKS ────────────────────────────────────────────────────────────
        address currentOwner = _owners[tokenId];
        if (currentOwner == address(0))  revert NotMinted(tokenId);
        if (currentOwner != from)        revert NotOwner(tokenId);
        if (to == address(0))            revert ZeroAddress();

        // ── EFFECTS ───────────────────────────────────────────────────────────
        // Clear the per-token approval — new owner starts with a clean slate.
        delete _tokenApprovals[tokenId];

        // Update ownership mapping.
        _owners[tokenId]  = to;

        // Update balance counters (unchecked: balances can never underflow
        // because we verified 'from' is the owner, so _balances[from] >= 1).
        unchecked {
            _balances[from] -= 1;
        }
        _balances[to] += 1;

        // ── INTERACTIONS ──────────────────────────────────────────────────────
        emit Transfer(from, to, tokenId);
    }

    // ─── Safe-receive check ───────────────────────────────────────────────────

    /// @dev Pings the recipient contract asking: "Do you handle ERC-721?"
    ///      Only called when `to` has code (i.e. is a contract).
    ///
    ///      HOW IT WORKS:
    ///      1. We call onERC721Received(operator, from, tokenId, data) on `to`.
    ///      2. An ERC-721-compatible contract must return:
    ///             bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
    ///             = 0x150b7a02
    ///      3. Any other return value (or a revert) means the contract can't
    ///         handle NFTs.  We revert so the NFT never leaves the sender.
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        // Only check contracts — regular wallets (EOAs) have no code.
        if (to.code.length == 0) return;

        try IERC721Receiver(to).onERC721Received(
            msg.sender,  // operator
            from,
            tokenId,
            data
        ) returns (bytes4 retval) {
            if (retval != IERC721Receiver.onERC721Received.selector)
                revert SafeTransferRejected(to);
        } catch {
            revert SafeTransferRejected(to);
        }
    }

    // ─── Approvals ────────────────────────────────────────────────────────────

    /// @inheritdoc IERC721
    function approve(address to, uint256 tokenId) external override {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert NotMinted(tokenId);

        // Only the owner or an approved operator can grant single-token approval.
        if (msg.sender != owner && !_operatorApprovals[owner][msg.sender])
            revert NotOwnerOrApproved();

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /// @inheritdoc IERC721
    function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @inheritdoc IERC721
    function getApproved(uint256 tokenId)
        external
        view
        override
        returns (address)
    {
        if (_owners[tokenId] == address(0)) revert NotMinted(tokenId);
        return _tokenApprovals[tokenId];
    }

    /// @inheritdoc IERC721
    function isApprovedForAll(address owner, address operator)
        external
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    // ─── Internal helper ──────────────────────────────────────────────────────

    /// @dev Returns true if `spender` is the owner, the token-level approved
    ///      address, or an operator approved for all of the owner's tokens.
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert NotMinted(tokenId);

        return
            spender == owner                           ||
            _tokenApprovals[tokenId] == spender        ||
            _operatorApprovals[owner][spender];
    }

    // ─── Metadata ─────────────────────────────────────────────────────────────

    /// @notice Returns the IPFS URI for a given token's metadata JSON.
    ///
    /// @dev    THE METADATA HOOK:
    ///         baseURI = "ipfs://QmYourCollectionHash/"
    ///         tokenURI(1)  → "ipfs://QmYourCollectionHash/1"
    ///         tokenURI(42) → "ipfs://QmYourCollectionHash/42"
    ///
    ///         Each path points to a JSON file like:
    ///         {
    ///           "name":        "MistyCoin Founding Member #1",
    ///           "description": "An original member of the MistyCoin community.",
    ///           "image":       "ipfs://QmImageHash/1.png",
    ///           "attributes":  [{ "trait_type": "Edition", "value": "Genesis" }]
    ///         }
    ///
    /// @param tokenId  The token whose metadata URI to return.
    /// @return         Full IPFS URI string.
    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        if (_owners[tokenId] == address(0)) revert NotMinted(tokenId);
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    // ─── Views ────────────────────────────────────────────────────────────────

    /// @inheritdoc IERC721
    function balanceOf(address owner)
        external
        view
        override
        returns (uint256)
    {
        if (owner == address(0)) revert ZeroAddress();
        return _balances[owner];
    }

    /// @inheritdoc IERC721
    function ownerOf(uint256 tokenId)
        external
        view
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert NotMinted(tokenId);
        return owner;
    }

    /// @notice Total tokens minted so far.
    function totalSupply() external view returns (uint256) {
        return nextTokenId - 1;
    }

    // ─── Admin ────────────────────────────────────────────────────────────────

    /// @notice Update the IPFS base URI (owner only).
    ///         Useful when migrating metadata to a permanent IPFS pin or Arweave.
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
}
