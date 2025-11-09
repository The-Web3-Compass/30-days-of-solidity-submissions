//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function ownerOf(uint256 tokenId) external view returns(address);
    function balanceOf(address user) external view returns(uint256);

    function approve(address approved, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns(address);
    function setApprovedForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns(bool);
    
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);
}

contract SimpleNFT is IERC721 {
    string public name;
    string public symble;

    uint256 private _tokenCount;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name_, string memory symble_) {
        name = name_;
        symble = symble_;
    }

    function ownerOf(uint256 tokenId) public view override returns(address) {
        address owner = _owners[tokenId];
        require(address(0) != owner, "Token doesn't exist");
        return owner;
    }

    function balanceOf(address user) external view override returns(uint256) {
        require(address(0) != user, "Invalid address");
        return _balances[user];
    }

    function approve(address approved, uint256 tokenId) external override {
        require(address(0) != approved, "Invalid address");
        address owner = ownerOf(tokenId);
        require(owner != approved, "Already owner");
        require(approved != getApproved(tokenId), "Already approved");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Not authorized");

        _tokenApprovals[tokenId] = approved;
        emit Approval(owner, approved, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns(address) {
        require(address(0) != _owners[tokenId], "Token doesn't exist");
        return _tokenApprovals[tokenId];
    }

    function setApprovedForAll(address operator, bool approved) external override {
        require(address(0) != operator, "Invalid address");
        require(operator != msg.sender, "Self approval");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns(bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) external override {
        require(_isOwnerOrApproved(from, tokenId), "Not authorized");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isOwnerOrApproved(from, tokenId), "Not authorized");
        _safeTransfer(from, to, tokenId, data);
    }

    function mint(address to, string memory uri) external {
        uint256 tokenId = _tokenCount;
        _tokenCount++;

        _owners[tokenId] = to;
        _balances[to] += 1;
        _tokenURIs[tokenId] = uri;

        emit Transfer(address(0), to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_owners[tokenId] != address(0), "Token doesn't exist");
        return _tokenURIs[tokenId];
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(address(0) != to, "Invalid address to");
        require(ownerOf(tokenId) == from, "Not owner");

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        delete _tokenApprovals[tokenId];

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "Not ERC721Receiver");
    }

    function _isOwnerOrApproved(address owner, uint256 tokenId) internal view returns(bool) {
        return (msg.sender == owner || 
                msg.sender == getApproved(tokenId) || 
                isApprovedForAll(owner, msg.sender)
        );
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns(bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns(bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch {
                return false;
            }
        }
        return true;
    }
}