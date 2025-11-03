//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes);

}

contract SimpleNFT is IERC721 {
    string public name;
    string public symbol;

    uint256 private _tokenIdCounter = 1;

    mapping(uint256 => address) private _owners; //存储特定代币id的地址有哪些
    mapping(address => uint256) private _balances; //某人有多少个代币
    mapping(uint256 => address) private _tokenApprovals; //授予某人临时许可
    mapping(address => mapping(address => bool)) private _operatorApprovals; //_operatorApprovals[Alice][Bob] = true 表示bob可以移动alice的任何NFT
    mapping(uint256 => string) private _tokenURIs; //映射每个令牌对应的元数据URL

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    //返回地址下有多少nft
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "zero address");
        return _balances[owner];

    }

    //返回这个令牌的拥有者
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "token doesnot exit");
        return owner;

    }

    //授权特定的人能转移特定的代币
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "already owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Not authorized");

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);

    }

    //检查谁被批准转移特定的代币
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_owners[tokenId] != address(0), "token dosenot exist");
        return _tokenApprovals[tokenId];

    }

    //允许用户批准或撤销给运营商对其nft的访问权限
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "self approval");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);

    }

    //检查是否被批准管理某人拥有的所有nft
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];

    }

    //将代币从一个人转移到另一个人
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not authorized");
        _transfer(from, to, tokenId);

    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");

    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not authorized");
        _safeTransfer(from, to, tokenId, data);

    }

    //创建一个新的nft
    function mint(address to, string memory uri) public {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _owners[tokenId] = to;
        _balances[to] += 1;
        _tokenURIs[tokenId] = uri;

        emit Transfer(address(0), to, tokenId);

    }

    //获取给定nft的元数据url
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_owners[tokenId] != address(0), "token doesnot exist");
        return _tokenURIs[tokenId];

    }

    //处理nft从一个钱包转移到另一个钱包
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "not owner");
        require(to != address(0), "zero address");

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        delete _tokenApprovals[tokenId];
        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "not erc721receiver");

    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));

    }

    //是否将nft发送给知道如何处理他的智能合约
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if(to.code.length > 0){
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            }catch {
                return false;
            }
        }
        return true;

    }

}