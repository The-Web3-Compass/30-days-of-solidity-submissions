// SPDX-License-Identifier: MIT
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract SimpleNFT is IERC721 {
    string public name;   // NFT收藏名称
    string public symbol; // 代码

    uint256 private _tokenIdCounter = 1; // 分配ID,从1开始

    mapping(uint256 => address) private _owners; // 代币拥有者
    mapping(address => uint256) private _balances; // 余额
    mapping(uint256 => address) private _tokenApprovals;  // 批准转移代币
    mapping(address => mapping(address => bool)) private _operatorApprovals; // B被授权允许管理A的NFT
    mapping(uint256 => string) private _tokenURIs; // 存储代币元数据URL

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    // 返回一个地址拥有多少NFT
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "Zero address");
        return _balances[owner];
    }

    // 给定一个代币ID，这告诉你谁拥有它
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token doesn't exist");
        return owner;
    }

    // 临时交出钥匙（不转移所有权）
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId); // 明确代币拥有者
        require(to != owner, "Already owner"); // 判断不是给自己转移代币
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Not authorized"); // 只有当你是所有者...或者你已经被所有者批准管理他们所有的代币（通过setApprovalForAll）时，你才能批准某人。

        _tokenApprovals[tokenId] = to; // 代币#123现在被批准由地址0xSomeOtherWallet转移
        emit Approval(owner, to, tokenId);
    }

    // 检查谁被批准转移特定代币
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_owners[tokenId] != address(0), "Token doesn't exist");
        return _tokenApprovals[tokenId];
    }

    // 让用户批准或撤销给定操作员
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "Self approval");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // 检查操作员是否被批准管理某人拥有的所有NFT
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // 代币转移：只有所有者或被批准的人可以这样做。使用_isApprovedOrOwner检查权限，然后调用_transfer实现代币转移。
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        _transfer(from, to, tokenId); // 可重复调用
    }

    // 安全转移的简化版本（快捷方式），传入空数据负载
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    // 安全转移（带数据）：实际工作
    // 1：访问控制检查；2.执行安全转移
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        _safeTransfer(from, to, tokenId, data);
    }

    // 铸造NFT
    function mint(address to, string memory uri) public {
        uint256 tokenId = _tokenIdCounter; // 为其分配唯一的tokenId
        _tokenIdCounter++;

        _owners[tokenId] = to; // 将所有权给予接收者
        _balances[to] += 1;
        _tokenURIs[tokenId] = uri; // 存储其元数据URI

        emit Transfer(address(0), to, tokenId);
    }

    // 获取给定NFT的元数据URL
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_owners[tokenId] != address(0), "Token doesn't exist");
        return _tokenURIs[tokenId];
    }

    // 内部函数，可重用的内部工具，transferFrom()和safeTransferFrom()的核心功能
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "Not owner");
        require(to != address(0), "Zero address");

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        delete _tokenApprovals[tokenId]; // 清除旧批准
        emit Transfer(from, to, tokenId);
    }

    // 内部函数，调用_checkOnERC721Received()进一步检查是否在向智能合约发送NFT
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "Not ERC721Receiver");
    }

    // 守门员函数：检查调用者是否被允许移动这个代币
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender)); // 调用的人是代币的实际所有者｜｜代币所有者给了这个特定的人移动这一个代币的权限｜｜代币所有者说，这个人可以管理我所有的代币
    }

    // _safeTransfer使用的安全检查:检查是否是在向知道如何处理NFT的智能合约发送这个NFT
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) { // 钱包地址没有代码，但合约有
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch {
                return false;
            }
        }
        return true; // 如果我们向普通钱包（不是合约）发送NFT，那么返回ture
    }
}

