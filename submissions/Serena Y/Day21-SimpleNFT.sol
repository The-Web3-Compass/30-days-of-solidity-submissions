// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC721 {//这是ERC-721接口，它定义了NFT合约必须实现的所有强制函数和事件
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

interface IERC721Receiver {//这个接口用于安全地向合约发送NFT。
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract SimpleNFT is IERC721 {//构建一个名为SimpleNFT的新合约，它将遵循ERC-721规则
    string public name;//名字
    string public symbol;//符号

    uint256 private _tokenIdCounter = 1;//初始tokenId为1，以后的以此类推

    mapping(uint256 => address) private _owners;//特定代币对应拥有者地址，#1代币拥有者是谁
    mapping(address => uint256) private _balances;//拥有着有多少代币
    mapping(uint256 => address) private _tokenApprovals;//NFT可以被批准由其他人转移 比如你批准opensea可以专业你的代币#4
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    //"我信任这个地址管理我所有的NFT——不仅仅是一个
    //_operatorApprovals[Alice][Bob] = true 意味着Bob被允许移动Alice拥有的任何NFT
    mapping(uint256 => string) private _tokenURIs;
    //代币指向的URL 每个代币可能有图像、描述，甚至可能是3D模型

    constructor(string memory name_, string memory symbol_) {//初始化代币的名字和符号
        name = name_;
        symbol = symbol_;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        //余额函数，返回余额
        require(owner != address(0), "Zero address");//owner的address不能为0
        return _balances[owner];//返回owner的余额
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
         //所有者函数，返回所有者
        address owner = _owners[tokenId];//对应上面的映射
        require(owner != address(0), "Token doesn't exist");//owner的address不能为0
        return owner;//返回owner地址
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);//根据tokenID获得owner地址
        require(to != owner, "Already owner");//检查to地址是不是已经是owner了
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Not authorized");

        _tokenApprovals[tokenId] = to;//允许To这个地址管理我的token#xx
        emit Approval(owner, to, tokenId);//公告 owner授予to 管理token#xx
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        //一个叫做getApproved的函数，需要输入tokenId 公开 可见 返回地址
        require(_owners[tokenId] != address(0), "Token doesn't exist");//需要to的地址不为0
        return _tokenApprovals[tokenId];//返回to的地址。授权给谁了
    }

    function setApprovalForAll(address operator, bool approved) public override {
        //一个叫做setApprovalForAll的函数，需要输入操作人地址和布尔值
        require(operator != msg.sender, "Self approval");//需要操作人不是msg.sender
        _operatorApprovals[msg.sender][operator] = approved;//msg.sender授予operator权限
        emit ApprovalForAll(msg.sender, operator, approved);//公告，msg.sender授予operator所有token的权限
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        //一个叫做isApprovedForAll的函数，用来检查二人是否有授权关系，需要输入owner和operator 返回是否授权的布尔值
        return _operatorApprovals[owner][operator];//返回布尔值
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        //一个叫做transferFrom的函数，需要输入从谁到谁转入，转入的tokenId是什么
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        //需要确保msg.sender是有权限转的
        _transfer(from, to, tokenId);//转账，从from 转到to 转了tokenId
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");//检查这个人有没有权限
        _safeTransfer(from, to, tokenId, data);//调用_safeTransfer转移tokenId
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public  override {//简易版
        this.safeTransferFrom(from, to, tokenId,"");//用户只是简单地从一个钱包向另一个钱包发送NFT时。
    }

    

    function mint(address to, string memory uri) public {//一个叫做铸造的函数，需要地址和url
        uint256 tokenId = _tokenIdCounter;//tokenID赋值
        _tokenIdCounter++;//赋值后tokenId计数器增加

        _owners[tokenId] = to;//tokenid的owner给to
        _balances[to] += 1;//to的余额增加1
        _tokenURIs[tokenId] = uri;//tkenid的url为uri

        emit Transfer(address(0), to, tokenId);//铸造成功
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        //一个叫做tokenURI的函数，需要输入tokenId 返回
        require(_owners[tokenId] != address(0), "Token doesn't exist");//需要满足tokenId的地址不为0
        return _tokenURIs[tokenId];//返回url
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        //一个叫做transfer的内部转账函数 输入地址从谁那转向谁，tokenID是多少
        require(ownerOf(tokenId) == from, "Not owner");//需要满足tokenId是属于from的，否则不可以转
        require(to != address(0), "Zero address");//to的地址不为0 否者就转给数据黑洞

        _balances[from] -= 1;//from的余额减去1
        _balances[to] += 1;//to的余额加一
        _owners[tokenId] = to;//tokenId的归属为to

        delete _tokenApprovals[tokenId];//如果有人之前被批准转移这个代币——我们删除该批准。
        emit Transfer(from, to, tokenId);//公告 from转给to tokenId
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        //更加安全的转移
        _transfer(from, to, tokenId);//调用transfer函数
        require(_checkOnERC721Received(from, to, tokenId, data), "Not ERC721Receiver");
        //调用_checkOnERC721Received()来检查，如果失败则回滚，检查to是普通钱包地址，检查合约是不是满足ERC721
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
        //检查一个地址是不是有权限，它可以使owner 可以是单个token授权的地址，可以是全部被授权的人。或运算
    }

    //_safeTransfer使用的安全检查
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {//如果to这个地址的代码大于0 说明它是合约
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                //尝试调用智能合约应该实现的函数onERC721Received
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch {
                return false;
            }
        }
        return true;//如果只是一个钱包返回true
    }
}

