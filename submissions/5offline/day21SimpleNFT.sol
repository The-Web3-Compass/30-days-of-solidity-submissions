//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//这次的东西和现实世界交互
//NFT:不可转让代币 独一无二的代币，Non-Fungible Token
//在游戏里买了皮肤，游戏没了皮肤没了， 但nft永远是你的，也可以根据这个建市场
//遵循 ERC-721 标准

interface IERC721 {
    //先写接口

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    //谁给谁转
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    //批准人
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    //操作人，是否批准了
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
   //和721的模版一样的
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    //有没有批准的功能
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    //两个safeTransferFrom是不一样的，又一个是calldata

}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
//安全地将 NFT 发送到合约 ，只有实现了这个接口的合约，才能安全接收 ERC721 代币。
contract SimpleNFT is IERC721 {

    string public name;
    string public symbol;

    uint256 private _tokenIdCounter = 1;
    //NFT都是唯一的，所以要设置代码，一二三号
    //从1开始，下一个铸造的时候直接代号+1

    mapping(uint256 => address) private _owners;
    //n号代币的拥有者是谁
    mapping(address => uint256) private _balances;
    //这个人有多少token
    mapping(uint256 => address) private _tokenApprovals;
    //n号代币被允许交易，可以在这里检查
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    //上一行的扩展版，这个人代理另外一个人所有的nft
    mapping(uint256 => string) private _tokenURIs;
    //这行会保存每个token的uri，而uri可以指向任何类型的东西
    //让nft不只是一种代币而是艺术音乐之类的

     constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }//nft要叫啥

     function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "Zero address");

        return _balances[owner];
        //看一下这个owner有多少token override是因为上面用了interface
    }
     function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token doesn't exist");
        return owner;
        //这个nft的拥有者是谁

    }
    function approve(address to, uint256 tokenId) public override {
        //寻求谁的批准
        address owner = ownerOf(tokenId);
        require(to != owner, "Already owner");
        //不用转移token
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Not authorized");
        //只有这个账户的本人或者代理操作全部的人才能做，随机钱包不可以
         _tokenApprovals[tokenId] = to;
         //把代币转过去，不转移所有权，只是暂时交代币，交123号给address to 
         emit Approval(owner, to, tokenId);
         }
         
         function isApprovedForAll(address owner, address operator) public view override returns (bool) {
            //批准全部操作，代理全部代币
            return _operatorApprovals[owner][operator];
    }
    
        function getApproved(uint256 tokenId) public view override returns (address) {
            require(_owners[tokenId] != address(0), "Token doesn't exist");
            return _tokenApprovals[tokenId];
         
         }//是不是被批准了可以操作
         
         function setApprovalForAll(address operator, bool approved) public override {
            require(operator != msg.sender, "Self approval");
             _operatorApprovals[msg.sender][operator] = approved;
             //设置要不要批准全部 或者全部暂停

             emit ApprovalForAll(msg.sender, operator, approved);

    }
         function _transfer(address from, address to, uint256 tokenId) internal virtual {
            //基础操作函数，后台内部转账
            require(ownerOf(tokenId) == from, "Not owner");
            require(to != address(0), "Zero address");
            
            _balances[from] -= 1;
            _balances[to] += 1;
            //更新余额
            _owners[tokenId] = to;
            //更新token的所有人
            
            delete _tokenApprovals[tokenId];
            //以前可以开门的人，把他们的钥匙丢掉，因为换主人了
            emit Transfer(from, to, tokenId);

         }

         function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
            _transfer(from, to, tokenId);
            //用内部转账功能
            require(_checkOnERC721Received(from, to, tokenId, data), "Not ERC721Receiver");
            //是否将这个 NFT 发送到智能合约，这个合约能接收吗，能接erc才能实现
            //写了下面的回来补足
        
            }
            function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
                //检查是否可以接erc721的智能合约
                 if (to.code.length > 0) {
                    //接收者是智能合约吗，大于0就是智能合约
                    try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                        //试一试看能不能处理，能就会返回值
                     return retval == IERC721Receiver.onERC721Received.selector;
                     } catch {
                        //如果接收者不是智能合约的话，抛出这个错误
                      //
                        return false;
                        }
                        
                 }
                 return true;
            }
            function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
                //像看门者 看有没有资格移动token
                 address owner = ownerOf(tokenId);
                 return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
                 //这些检查中的任何一个返回 true，则调用方有权继续
                 
                 }

             function transferFrom(address from, address to, uint256 tokenId) public override {
                //如果被授权就可以干这件事
                require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
                _transfer(from, to, tokenId);
                
                }
            function safeTransferFrom(address from, address to, uint256 tokenId) public override {
                //不带数据安全地传输，快捷方式，只想从a转到b
                safeTransferFrom(from, to, tokenId, "");
                }

            function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
                require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
                //因为这次要数据，所以要看一下是不是被授权的人
                _safeTransfer(from, to, tokenId, data);
                //调用_safeTransfer，里面也会看是否接收erc20
                
                }

                function mint(address to, string memory uri) public {
                    
                    uint256 tokenId = _tokenIdCounter;
                    _tokenIdCounter++;
                    //每次铸造代币+1
                     _owners[tokenId] = to;
                     _balances[to] += 1;
                     _tokenURIs[tokenId] = uri;
                     //更新uri
                     emit Transfer(address(0), to, tokenId);
                 }

                 function tokenURI(uint256 tokenId) public view returns (string memory) {
                    //代币里的详细信息，每个token和uri都是不同的
                    require(_owners[tokenId] != address(0), "Token doesn't exist");
                    return _tokenURIs[tokenId];
                    
                    }
                    //要把不同函数分成不同块，有些用external，有些internal
                    //要有钱包，可以用测试币来试试

}
//有sepolia eth才能运行
//pinata.cloud 可以上传文件 给了cid 
//把cid加进去，可以在钱包里看到这个nft
//在本地部署要加一个jason

             







            
    















