//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//IERC721 接口
//NFT的官方标准接口，定义了ERC721必须实现的所有功能
interface IERC721 {

    //Transfer：当NFT从一个地址转给另一个地址时触发。
    //所有NFT转移都必须发出这个事件
    //三个 indexed 参数是为了方便在区块链上用事件过滤器（Filter）查询
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    //Approval：当NFT所有者授权他人可操作某个NFT时触发
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    //ApprovalForAll：当NFT所有者授权某个“操作员”可以操作他所有NFT时触发
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    //balanceOf(address owner)：返回一个地址持有的NFT数量
    function balanceOf(address owner) external view returns (uint256);
    //ownerOf(uint256 tokenId)：返回某个NFT的拥有者地址
    function ownerOf(uint256 tokenId) external view returns (address);

    //approve(address to, uint256 tokenId)：授权某个地址可以转移特定NF
    function approve(address to, uint256 tokenId) external;
    //getApproved(uint256 tokenId)：查询某个NFT目前被授权给谁
    function getApproved(uint256 tokenId) external view returns (address);

    //setApprovalForAll(address operator, bool approved)：授权某人操作自己所有NFT
    function setApprovalForAll(address operator, bool approved) external;
    //isApprovedForAll(address owner, address operator)：查询是否已授权
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    //transferFrom(...)：转移NFT（不检查安全性）
    function transferFrom(address from, address to, uint256 tokenId) external;

    //safeTransferFrom(...)：安全转移NFT（防止丢失）
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}
//PsPs？定义了 ERC721 标准的必要接口，让外界（钱包、市场、其他合约）知道这个合约是 NFT 类型，并且能与之交互


//IERC721Receiver 接口
//当NFT被安全转移 (safeTransferFrom) 到一个合约时，
//这个接口确保接收方合约知道如何正确处理NFT
interface IERC721Receiver {

    //接收 NFT 时调用的函数
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
//确保 NFT 安全转移到合约地址时不会“丢失”，检查目标是否能安全接收 NFT


//主合约 SimpleNFT
//定义了一个新合约 SimpleNFT，并声明它遵循 IERC721 接口。
//这意味着我们必须实现上面接口里的所有函数
contract SimpleNFT is IERC721 {
    string public name;     //NFT系列的名字
    string public symbol;     //NFT系列的简称

    //_tokenIdCounter:自增计数器，用于生成新的NFT ID
    uint256 private _tokenIdCounter = 1;    

    mapping(uint256 => address) private _owners;     //映射每个NFT的所有者
    mapping(address => uint256) private _balances;     //映射某个地址拥有的NFT数量
    mapping(uint256 => address) private _tokenApprovals;     //存储“单个NFT”的授权信息
    mapping(address => mapping(address => bool)) private _operatorApprovals;      //存储“全局授权”信息。表示 Alice 授权 Bob 操作她的所有NF
    mapping(uint256 => string) private _tokenURIs;     //存储NFT的元数据UR
    //PsPs：定义整个NFT系统的数据存储结构，用于记录所有权、授权状态和元数据


    //当部署合约时，开发者初始化NFT名称与符号。
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    //balanceOf 查询余额函数
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "Zero address");     //确保查询地址不是0x0（无效地址）
        return _balances[owner];     //返回该地址的NFT数量
    }
    //PsPs：查询某个地址持有多少个 NFT


    //ownerOf 查询持有人
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];     //查询指定tokenId的拥有者
        require(owner != address(0), "Token doesn't exist");      //如果未被铸造（owner=0地址），则报错
        return owner;     //返回真实持有人地址
    }
    //PSPs：查询一个 NFT 的实际持有者


    //approve 函数：单个 NFT 授权
    //声明一个 公共函数 approve，允许外部用户调用
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);     //找出该NFT的当前拥有者
        require(to != owner, "Already owner");     //确保授权的对象不是自己
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Not authorized");     //确保调用者有权授权（自己或被owner全权授权者）
        _tokenApprovals[tokenId] = to;     //保存授权记录
        emit Approval(owner, to, tokenId);     //发出 Approval 事件
    }

    //getApproved 函数：查询单个授权
    //定义了一个查询函数，输入 tokenId，返回对应被授权的地址
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_owners[tokenId] != address(0), "Token doesn't exist");     //检查这个 token 是否存在
        return _tokenApprovals[tokenId];     //返回之前在 approve() 里存下来的授权地址
    }
    //查询某个 NFT 当前被授权给谁，用于显示“谁能卖这个NFT”


    //setApprovalForAll 函数：批量授权所有NFT
    //定义一个允许用户一次性授权别人操作自己所有NFT的函数
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "Self approval");     //检查不能对自己授权
        _operatorApprovals[msg.sender][operator] = approved;     //记录授权状态
        emit ApprovalForAll(msg.sender, operator, approved);     //触发事件，让外界知道这次授权变更
    }
    //PsPs：让用户可以一次性授权（或取消授权）别人管理自己所有NFT


    //isApprovedForAll 函数：查询批量授权状态
    //查询函数，用于检查某个 operator 是否被 owner 授权管理他所有NFT
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        //直接从映射中取出布尔值，true 表示已授权，false 表示未授权
        return _operatorApprovals[owner][operator];
    }

    //transferFrom — 普通转移函数
    //声明一个公开函数 transferFrom，让别人或自己可以转移 NFT
    function transferFrom(address from, address to, uint256 tokenId) public override {
        //检查调用者 msg.sender 是否有权转移该 NFT
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        //用内部函数 _transfer() 来真正执行转移逻辑
        _transfer(from, to, tokenId);
    }
    
    //safeTransferFrom — 安全转移
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        //验证调用者身份是否合法
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        //调用内部的 _safeTransfer 执行转移逻辑
        _safeTransfer(from, to, tokenId, data);
    }

    //这是一个 公开函数，任何人都能调用（如果没有额外权限控制）
    function mint(address to, string memory uri) public {
        //从 _tokenIdCounter 里取出当前可用的 token 编号
        uint256 tokenId = _tokenIdCounter;
        //计数器加一，为下次铸造做准备
        _tokenIdCounter++;

        //把这个新 token 的拥有者设置为传入的 to 地址
        _owners[tokenId] = to;
        //更新接收者的 NFT 持有数量
        _balances[to] += 1;
        //把传入的 uri 绑定到这个 NFT
        _tokenURIs[tokenId] = uri;

        //发出一个标准的 Transfer 事件
        emit Transfer(address(0), to, tokenId);
    }

    // tokenURI() —— 读取 NFT 的元数据链接
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        //确保要查询的 NFT 已经存在
        require(_owners[tokenId] != address(0), "Token doesn't exist");
        //返回对应的元数据链接
        return _tokenURIs[tokenId];
    }

    //_transfer — 实际转移逻辑
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        //确认传入的 from 地址确实是该 token 的拥有者
        require(ownerOf(tokenId) == from, "Not owner");
        //不允许转移到地址 0（即销毁地址）
        require(to != address(0), "Zero address");

        _balances[from] -= 1;     //发送方减少 1
        _balances[to] += 1;     //接收方增加 1
        _owners[tokenId] = to;     //改变 token 拥有者映射，标记新主人

        delete _tokenApprovals[tokenId];     //删除之前的授权记录
        emit Transfer(from, to, tokenId);     //发出 Transfer 事件，通知全链（钱包、市场等）这个NFT换了主人
    }

    //_safeTransfer — 安全转移逻辑（带接收检测）
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);      //调用上面的 _transfer，执行基本转移
        require(_checkOnERC721Received(from, to, tokenId, data), "Not ERC721Receiver");     //检查接收方是否能安全接收NFT
    }
    //_safeTransfer = _transfer + 安全检查
    //用于防止 NFT 被错误地发送到无法处理 NFT 的合约地址


    //_isApprovedOrOwner — 检查权限
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);     //获取当前拥有者

        //判断三种情况是否成立，只要有一种为真，返回 true
        //1.调用者就是拥有者
        //2.调用者是单个授权人
        //3.调用者是批量授权人
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    //_checkOnERC721Received — 安全检测函数
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {     //检查接收方 to 是否是一个合约地址

            //尝试调用该合约的 onERC721Received 函数
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                //如果函数返回正确的选择器，表示合约能安全接收NFT
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch {
                //否则返回 false
                return false;
            }
        }

        //如果接收方是普通钱包地址（非合约），直接返回 true，因为钱包地址可以直接收NFT
        return true;
    }
}
