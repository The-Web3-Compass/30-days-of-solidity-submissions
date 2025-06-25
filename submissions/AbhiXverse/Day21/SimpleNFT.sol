// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721.sol";

contract SimpleNFT is ERC721, ERC721Metadata, ERC165 {
    // State variables
    address public contractOwner;
    uint256 public totalSupply;
    uint256 public usedSupply;
    uint256 private _nextTokenId;

    string private _name;
    string private _symbol;

    mapping(uint256 tokenId => address owner) private _owners;
    mapping(uint256 tokenId => string uri) private _tokenURIs;
    mapping(address owner => uint256 balance) private _balances;
    mapping(uint256 tokenId => address) private _approvals;
    mapping(address owner => mapping(address operator => bool isApproved)) private _operators;

    // Custom errors
    error NonExistentToken();
    error NotTokenOwner();

    // Constructor
    constructor(string memory name_, string memory symbol_, uint256 totalSupply_) {
        require(totalSupply_ > 0, "SimpleNFT: Total supply must be greater than 0");
        contractOwner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _nextTokenId = 1;
        totalSupply = totalSupply_;
    }

    // Modifiers
    modifier requireTokenOwner(uint256 _tokenId) {
        if (_owners[_tokenId] != msg.sender) revert NotTokenOwner();
        _;
    }

    modifier requireTokenExists(uint256 _tokenId) {
        if (_owners[_tokenId] == address(0)) revert NonExistentToken();
        _;
    }

    modifier requireOwnerOrOperator(uint256 _tokenId) {
        require(msg.sender == _owners[_tokenId] || _operators[_owners[_tokenId]][msg.sender], "SimpleNFT: caller is neither token owner nor approved operator");
        _;
    }

    // ERC721 Functions
    function balanceOf(address _owner) public view returns (uint256) {
        require (_owner != address(0), "SimpleNFT: balance query for the zero address");
        return _balances[_owner];
    }

    function ownerOf(uint256 _tokenId) requireTokenExists(_tokenId) public view returns (address) {
        return _owners[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public payable {
        transferFrom(_from, _to, _tokenId);
        if (_to.code.length > 0) {
            require(
                ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
                "SimpleNFT: transfer to non ERC721Receiver implementer contract"
            );
        }
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) requireTokenExists(_tokenId) public payable {
        require(_to != address(0), "SimpleNFT: transfer to the zero address");
        require(_owners[_tokenId] == _from, "SimpleNFT: transfer from the wrong owner");
        require(
            msg.sender == _owners[_tokenId] || msg.sender == _approvals[_tokenId] || _operators[_owners[_tokenId]][msg.sender],
            "SimpleNFT: caller is not authorized"
        );

        _owners[_tokenId] = _to;
        _balances[_from] -= 1;
        _balances[_to] += 1;

        _approvals[_tokenId] = address(0);
        emit Approval(_from, address(0), _tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) requireTokenExists(_tokenId) requireOwnerOrOperator(_tokenId) public payable {
        _approvals[_tokenId] = _approved;
        emit Approval(_owners[_tokenId], _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        _operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) requireTokenExists(_tokenId) public view returns (address) {
        return _approvals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operators[_owner][_operator];
    }

    // ERC165 support
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(ERC721).interfaceId
            || interfaceId == type(ERC721Metadata).interfaceId
            || interfaceId == type(ERC165).interfaceId;
    }

    // ERC721Metadata Functions
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 _tokenId) requireTokenExists(_tokenId) public view returns (string memory) {
        return _tokenURIs[_tokenId];
    }

    // Mint new token
    function mint(address _to, string memory _tokenURI) public returns (uint256 tokenId) {
        require(msg.sender == contractOwner, "SimpleNFT: Only owner can mint");
        require(usedSupply < totalSupply, "SimpleNFT: Minting limit reached");
        require(_to != address(0), "SimpleNFT: Transfer to the zero address");
        require(bytes(_tokenURI).length > 0, "SimpleNFT: Token URI cannot be empty");

        tokenId = _nextTokenId;
        usedSupply += 1;
        _tokenURIs[tokenId] = _tokenURI;
        _nextTokenId += 1;

        _owners[tokenId] = _to;
        _balances[_to] += 1;

        emit Transfer(address(0), _to, tokenId);
    }

    // Burn token
    function burn(uint256 _tokenId) requireTokenExists(_tokenId) requireTokenOwner(_tokenId) public {
        _owners[_tokenId] = address(0);
        _tokenURIs[_tokenId] = "";
        _balances[msg.sender] -= 1;
        _approvals[_tokenId] = address(0);

        emit Transfer(msg.sender, address(0), _tokenId);
    }
}
