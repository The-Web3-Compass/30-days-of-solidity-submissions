// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day21_IERC721.sol";
import "./day21_IERC721Receiver.sol";

contract SimpleNFT is IERC721, IERC721Receiver {

    // NFT 名称
    string public name;
    // 简称
    string public symbol;

    // nft id,每次+1
    uint256 private serialId = 1;

    // nft -> 用户
    mapping(uint256 => address) private _owners;
    // 用户 -> nft数量
    mapping(address => uint256) private _balances;
    // nft  允许被谁代为操作
    mapping(uint256 => address) private _tokenApprovals;
    // A授权B操作所有NFT
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    // nft id-> url
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }


    // 查询用户拥有的nft数量
    function balanceOf(address owner) external view returns (uint256){
        require(owner != address(0) , "Zero address");
        return _balances[owner];
    }
    // 查询nft属于谁
    function ownerOf(uint256 tokenId) public  view returns (address){
        address owner = _owners[tokenId];
        require(owner != address(0), "Token doesn't exist");
        return owner;
    }
    // nft A授权用户B操作
    function approve(address to, uint256 tokenId) external{
        address owner = ownerOf(tokenId);

        require(owner != to , "already approve");
        require(owner == msg.sender || isApprovedForAll(owner, msg.sender), "Not authorized");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    function getApproved(uint256 tokenId) public view returns (address){
        require(_owners[tokenId] != address(0), "Token doesn't exist");
        return _tokenApprovals[tokenId];
    }

    // 授权用户B操作所有NFT权限
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Self approval");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view  override  returns (bool){
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");

    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        _safeTransfer(from, to, tokenId, data);
    }

   function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "Not owner");
        require(to != address(0), "Zero address");

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        delete _tokenApprovals[tokenId];
        emit Transfer(from, to, tokenId);
    }

    function mint(address to, string memory uri) public {
        uint256 tokenId = serialId;
        serialId++;

        _owners[tokenId] = to;
        _balances[to] += 1;
        _tokenURIs[tokenId] = uri;

        emit Transfer(address(0), to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "Not ERC721Receiver");
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch {
                return false;
            }
        }
        return true;
    }
    function onERC721Received(address , address , uint256 , bytes calldata ) external pure returns (bytes4){
        // 返回固定的 4 字节选择器，用来告诉发送方 “我接收成功了”
        return IERC721Receiver.onERC721Received.selector;
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
   
}