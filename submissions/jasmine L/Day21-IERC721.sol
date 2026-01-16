// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721{
    event Transfer(address indexed _form, address indexed _to, uint256 indexed tokenId);//转移事件
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);//批准
    event ApprovalForAll(address indexed _owner, address indexed operator, bool _approved);//批准转移所有的NFT
    // 记录谁拥有什么
    
    // 为NFT收藏提供名称和符号
    // 所有者批准其他人转移他们的NFT

    
    function balanceOf(address _owner) external view returns (uint256); // 每个人拥有多少NFT
    function ownerOf(uint256 _tokenId) external view returns(address); //这个非同质化代币是谁的？
    
    
    function approve(address _to, uint256 _tokenId) external; // 批准给_to 的_tokenId
    function getApproved(uint256 _tokenId)external view returns(address); //该代币是否被批准了
    
    function setApprovalForAll(address _operator, bool _approved) external ;
    //是否已经全权代理给别人了 把所有代币
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    
    // 转账与安全转账
    function transferFrom(address _from, address _to, uint256 _tokenId) external ;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data)external ;
    
}

interface IERC721Receiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);    
}

contract SimpleNFT is IERC721{
    string public name;
    string public symbol;

    uint256 private _tokenIdCounter = 1;

    mapping (uint256 => address) private _owners;//代币所有者地址
    mapping (address => uint256) private _balances;//该地址有多少代币
    mapping (uint256 => address) private _tokenApprovals;//可以被批准由其他人转移
    mapping (address => mapping (address => bool)) private _operatorApprovals;//允许代理人管理所有代币
    mapping (uint256 => string) private _tokenURIs;//存储每个代币的元数据，比如图像、描述甚至是3D模型

    constructor(string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address _owner) public view override returns (uint256){
        require(_owner!=address(0), "Invaild address");
        return _balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view override returns(address){
        address owner = _owners[_tokenId];
        require(owner!=address(0), "Not Exist");
        return owner;
    }

    function approve(address _to, uint256 _tokenId) public override {
        address owner = ownerOf(_tokenId);
        require(_to!=owner, "Already owner");//不能转给本人
        require(msg.sender==owner|| isApprovedForAll(owner, msg.sender), "Not authorization");
        _tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }
    //批准给谁了
     function getApproved(uint256 _tokenId) public override  view returns(address){
        require(_owners[_tokenId] != address(0),"Not exist");
        return _tokenApprovals[_tokenId];
     }
     //批准或者撤销都可以
    function setApprovalForAll(address _operator, bool _approved) public override {
        require(_operator != msg.sender, "Already owner");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    //相当于把独一无二的东西卖掉了此处只做转移操作，不做权限检查
    function _transfer(address _from, address _to, uint256 _tokenId) internal virtual{
        //好像没看是否这俩地址是否相等，不能本人转本人吧，转了好像也不会出什么大事，只会浪费gas
        require(ownerOf(_tokenId)==_from, "Not Owner");//from地址是否为代币所有者
        require(_to != address(0), "Invaild address");
        _balances[_from] -= 1;
        _balances[_to] +=1;
        _owners[_tokenId] = _to;
        delete _tokenApprovals[_tokenId];
        //假如是被批准了所有代币转移呢？
        emit Transfer(_from, _to, _tokenId);
    }
    // 是否在向智能合约发送NFT，以及智能合约是否可以接受转账NFT
    function _safeTransfer(address _from, address _to, uint256 _tokenId, bytes memory data) internal virtual {
        _transfer(_from,_to,_tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId,data), "Not ERC721Receiver");
    }

    function _checkOnERC721Received(address _from, address _to,uint256 _tokenId, bytes memory data)private returns (bool){
        //存在代码的就是智能合约
        if(_to.code.length(bool)){
            try IERC721Receiver(_to).onERC721Received(msg.sender,_from, _tokenId,data) returns(bytes retval){
                return retval == IERC721Receiver.onERC721Received.selector;
            }catch{
                return false;
            }
        }
        return true;
    }
    
    function isApprovedForAll(address _owner, address _operator) public view override  returns (bool){
        return _operatorApprovals[_owner][_operator];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        require(_isApprovedOrOwner(msg.sender,_tokenId), "Not authorization");
        _transfer(_from, _to, _tokenId, "");
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override{
        safeTransferFrom(_from,_to,_tokenId);
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data)public  override {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not authorized");
        _safeTransfer( _from,  _to,  _tokenId,  _data);
    }
    function _isApprovedOrOwner(address _spender, uint256 _tokenId)internal view returns(bool){
        address owner = ownerOf(_tokenId);
        return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
    }

    function mint(address _to, string memory uri)public {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _owners[tokenId] =_to;
        _balances[_to] +=1;
        _tokenURIs[tokenId] = uri;

        emit Transfer(address(0), _to, tokenId);    
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory){
        require(_owners[_tokenId]!=address(0),"Not exist");
        return _tokenURIs[_tokenId];
    }

}