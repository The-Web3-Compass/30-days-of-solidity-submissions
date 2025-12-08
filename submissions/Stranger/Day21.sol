// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 定义接口
interface IERC721 {
    // NFT转移事件, 向某地址对某NFT授权事件, 向某地址对所有NFT的授权事件
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256); // 某用户的NFT余量
    function ownerOf(uint256 tokenId) external view returns (address); // 某NFT的属主

    function approve(address to, uint256 tokenId) external;   // 向某用户对某NFT授权
    function getApproved(uint256 tokenId) external view returns (address); // 获取某NFT的授权用户

    function setApprovalForAll(address operator, bool approved) external; // 向某人设置对所有NFT的授权
    function isApprovedForAll(address owner, address operator) external view returns (bool); // 查询属主是否向某人授权了名下所有NFT的

    function transferFrom(address from, address to, uint256 tokenId) external;      // 转移某NFT
    function safeTransferFrom(address from, address to, uint256 tokenId) external;  // 安全转移某NFT
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;  // 安全转移某NFT并带附加信息
}

// 处理安全转移的接口
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract SimpleNFT is IERC721 {
    // NFT的名称及标识
    string public name;
    string public symbol;
    
    // NFT的ID(从1开始)
    uint256 private _tokenIdCounter = 1;

    mapping(uint256 => address) private _owners;           // NFT -> 属主
    mapping(address => uint256) private _balances;         // 用户 -> NFT余量
    mapping(uint256 => address) private _tokenApprovals;   // NFT -> 临时授权用户
    mapping(address => mapping(address => bool)) private _operatorApprovals;  // 属主向特定人员对管理名下所有NFT的授权
    mapping(uint256 => string) private _tokenURIs;         // NFT -> URI

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    // 获取某人的NFT余量
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "Zero address");
        return _balances[owner];
    }

    // 获取某NFT的属主
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token doesn't exist");
        return owner;
    }

    // 向某人临时授权处理某NFT, 同时更新NFT临时授权情况的映射
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "Already owner");
        // 只有代币的属主或者被授权管理属主所有NFT的人才有权向他人授权
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Not authorized");

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    // 获取NFT的临时授权用户
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_owners[tokenId] != address(0), "Token doesn't exist");
        return _tokenApprovals[tokenId];
    }

    // 向某人授权对名下所有NFT的管理权限
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "Self approval");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // 获取某人是否向特定人员授权管理名下所有NFT
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // 检查权限后转移NFT
    function transferFrom(address from, address to, uint256 tokenId) public override {
        // 只有属主、临时授权及有管理权用户才能转移NFT
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        _transfer(from, to, tokenId);
    }

    // 安全转移
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    // 带附加数据的安全转移
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        _safeTransfer(from, to, tokenId, data);
    }

    // 铸造NFT: 分配ID, 分配属主, 更新属主余量及NFT的元数据并完成铸造（转移权限）
    function mint(address to, string memory uri) public {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _owners[tokenId] = to;
        _balances[to] += 1;
        _tokenURIs[tokenId] = uri;

        emit Transfer(address(0), to, tokenId);
    }

    // 获取存储NFT元数据的URI
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_owners[tokenId] != address(0), "Token doesn't exist");
        return _tokenURIs[tokenId];
    }

    // 处理实际转移操作
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        // NFT只能从属主向其他有效地址转移
        require(ownerOf(tokenId) == from, "Not owner");
        require(to != address(0), "Zero address");

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        delete _tokenApprovals[tokenId];  // 删除旧的属主对某NFT的临时授权
        emit Transfer(from, to, tokenId);
    }

    // 安全转移, 较之于转移多了后续检查, 当检查未通过时会回滚交易
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "Not ERC721Receiver");
    }

    // 查询某人是否有权转移某NFT, 只有属主、临时授权用户及有名下所有管理权的用户才是合法权限用户
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    // 处理安全检查, 当接收者位智能合约时检查它是否能成功调用否则回滚交易
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
}

