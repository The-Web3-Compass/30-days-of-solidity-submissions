// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721.sol";

/**
 * @title SimpleNFT
 * @author shivam
 * @notice This contract implements a simple ERC721 NFT collection with basic minting and metadata functionality.
 * @dev Inherits from ERC721, ERC721Metadata, and ERC165. Allows minting NFTs with metadata, tracking ownership, and querying token information.
 * @dev Implemented by following official EIP: https://eips.ethereum.org/EIPS/eip-721
 */
contract SimpleNFT is ERC721, ERC721Metadata, ERC165 {
    // --- State Variables ---
    
    /// @notice Contract owner
    address public contractOwner;

    /// @notice Total supply of tokens
    uint256 public totalSupply;

    /// @notice Used supply of tokens
    uint256 public usedSupply;

    /// @notice Next token ID
    uint256 private _nextTokenId;

   /// @notice Name of token
   string private _name;
   /// @notice Symbol of token
   string private _symbol;

   /// @notice Mapping of token ID to owner
   mapping(uint256 tokenId => address owner) private _owners;

   /// @notice Mapping of token ID to URI
   mapping(uint256 tokenId => string uri) private _tokenURIs;

   /// @notice Mapping of owner address to balance
   mapping(address owner => uint256 balance) private _balances;

   /// @notice Mapping of token ID to approved address
   mapping(uint256 tokenId => address) private _approvals;

   /// @notice Mapping of owner address to approved operators
   mapping(address owner => mapping(address operator => bool isApproved)) private _operators;

    // --- Custom Errors ---

    /// @notice Error thrown when the token does not exist
    error NonExistentToken();

    /// @notice Error thrown when the caller is not the owner of the token
    error NotTokenOwner();
    
    // --- Constructor ---

    /// @notice Initializes the contract by setting the contract owner, name and symbol
    constructor(string memory name_, string memory symbol_, uint256 totalSupply_) {
        require(totalSupply_ > 0, "SimpleNFT: Total supply must be greater than 0");
        contractOwner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _nextTokenId = 1;
        totalSupply = totalSupply_;
    }

    // --- Modifiers ---

    /// @notice Modifier to check if caller is owner of token
    modifier requireTokenOwner(uint256 _tokenId) {
        if (_owners[_tokenId] != msg.sender) revert NotTokenOwner();
        _;
    }

    /// @notice Modifier to check if token exists
    modifier requireTokenExists(uint256 _tokenId) {
        if (_owners[_tokenId] == address(0)) revert NonExistentToken();
        _;
    }

    /// @notice Modifier to check if caller is owner of token or operator of token owner
    modifier requireOwnerOrOperator(uint256 _tokenId) {
        require(msg.sender == _owners[_tokenId] || _operators[_owners[_tokenId]][msg.sender], "SimpleNFT: caller is neither token owner nor approved operator");
        _;
    }

    // --- ERC721 Functions ---

    /// @inheritdoc ERC721
    function balanceOf(address _owner) public view returns (uint256) {
        require (_owner != address(0), "SimpleNFT: balance query for the zero address");
        return _balances[_owner];
    }

    /// @inheritdoc ERC721
    function ownerOf(uint256 _tokenId) requireTokenExists(_tokenId) public view returns (address) {
        return _owners[_tokenId];
    }

    /// @inheritdoc ERC721
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public payable {
        transferFrom(_from, _to, _tokenId);
        if (_to.code.length > 0) {
            require(ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data) == ERC721TokenReceiver.onERC721Received.selector, "SimpleNFT: transfer to non ERC721Receiver implementer contract");
        }
    }

    /// @inheritdoc ERC721
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @inheritdoc ERC721
    function transferFrom(address _from, address _to, uint256 _tokenId) requireTokenExists(_tokenId) public payable {
        // check to address
        require(_to != address(0), "SimpleNFT: transfer to the zero address");

        // check token owner
        require(_owners[_tokenId] == _from, "SimpleNFT: transfer from the wrong owner");

        // check caller is authorized
        require(msg.sender == _owners[_tokenId] || msg.sender == _approvals[_tokenId] || _operators[_owners[_tokenId]][msg.sender], "SimpleNFT: caller is not authorized");

        // perform transfer of token
        _owners[_tokenId] = _to;
        _balances[_from] -= 1;
        _balances[_to] += 1;

        // clear approval
        address newApproved = address(0);
        _approvals[_tokenId] = newApproved;
        emit Approval(_from, newApproved, _tokenId);

        // emit event
        emit Transfer(_from, _to, _tokenId);
    }

    /// @inheritdoc ERC721
    function approve(address _approved, uint256 _tokenId) requireTokenExists(_tokenId) requireOwnerOrOperator(_tokenId) public payable {
        _approvals[_tokenId] = _approved;
        emit Approval(_owners[_tokenId], _approved, _tokenId);
    }

    /// @inheritdoc ERC721
    function setApprovalForAll(address _operator, bool _approved) public {
        _operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @inheritdoc ERC721
    function getApproved(uint256 _tokenId) requireTokenExists(_tokenId) public view returns (address) {
        return _approvals[_tokenId];
    }

    /// @inheritdoc ERC721
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operators[_owner][_operator];
    }
    
    // --- ERC165 Functions ---

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(ERC721).interfaceId
            || interfaceId == type(ERC721Metadata).interfaceId
            || interfaceId == type(ERC165).interfaceId;
    }

    // --- ERC721Metadata Functions ---

    /// @inheritdoc ERC721Metadata
    function name() public view returns (string memory) {
        return _name;
    }

    /// @inheritdoc ERC721Metadata
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc ERC721Metadata
    function tokenURI(uint256 _tokenId) requireTokenExists(_tokenId) public view returns (string memory) {
        return _tokenURIs[_tokenId];
    }

    // --- Other functions ---

    /// @notice Mints a new token and assigns it to the specified address
    /// @param _to The address to which the token will be assigned
    /// @param _tokenURI The metadata URI for the token
    /// @return tokenId The ID of the newly minted token
    /// @dev Only the contract owner can mint new tokens
    function mint(address _to, string memory _tokenURI) public returns (uint256 tokenId) {
        // check caller
        require(msg.sender == contractOwner, "SimpleNFT: Only owner can mint");
        // check minting limit
        require(usedSupply < totalSupply, "SimpleNFT: Minting limit reached");
        // check to address
        require(_to != address(0), "SimpleNFT: Transfer to the zero address");
        // check token URI
        require(bytes(_tokenURI).length > 0, "SimpleNFT: Token URI cannot be empty");

        tokenId = _nextTokenId;
        
        // create new token
        usedSupply += 1;
        _tokenURIs[tokenId] = _tokenURI;
        _nextTokenId += 1;

        // give token
        _owners[tokenId] = _to;
        _balances[_to] += 1;

        emit Transfer(address(0), _to, tokenId);
    }

    /// @notice Burns a token, destroying it permanently
    /// @param _tokenId The ID of the token to burn
    /// @dev Only the owner of the token can burn it.
    function burn(uint256 _tokenId) requireTokenExists(_tokenId) requireTokenOwner(_tokenId) public {
        // burn token
        _owners[_tokenId] = address(0);
        _tokenURIs[_tokenId] = "";
        _balances[msg.sender] -= 1;
        _approvals[_tokenId] = address(0);
        
        // NOTE: Not decreasing usedSupply, once a token is gone, it is gone forever

        emit Transfer(msg.sender, address(0), _tokenId);
    }
}