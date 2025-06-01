// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint);
    function ownerOf(uint tokenId) external view returns (address);

    function approve(address to, uint tokenId) external;
    function getApproved(uint tokenId) external view returns (address);

    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function transferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract SimpleNFT is IERC721 {
    string public name;
    string public symbol;

    uint private tokenCounter = 1;

    mapping(uint => address) private owners;
    mapping(address => uint) private balances;
    mapping(uint => address) private tokenApprovals;
    mapping(address => mapping(address => bool)) private operatorApprovals;
    mapping(uint => string) private tokenURIs;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address _owner) public view override returns (uint) {
        require(_owner != address(0), "invalid/xero address");
        return balances[_owner];
    }

    function ownerOf(uint _tokenId) public view override returns (address) {
        address owner = owners[_tokenId];
        require(owner != address(0), "token deos not exist");

        return owner;
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view override returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function approve(address _to, uint _tokenId) public override {
        address owner = ownerOf(_tokenId);

        require(owner != address(0), "token deos not exist");
        require(
            owner != msg.sender || isApprovedForAll(owner, msg.sender),
            "not authorized"
        );

        tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

    function _transfer(address _from, address _to, uint _tokenId) internal {
        require(ownerOf(_tokenId) == _from, "not ur token");
        require(_to != address(0), "invalid address");

        balances[_from] -= 1;
        balances[_to] += 1;
        owners[_tokenId] = _to;

        delete tokenApprovals[_tokenId];
        emit Transfer(_from, _to, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint _tokenId
    ) public override {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "not approved");
        _transfer(_from, _to, _tokenId);
    }

    function _safeTransfer(
        address _from,
        address _to,
        uint _tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(_from, _to, _tokenId);
        require(checkOnIERC721Received(_from, _to, _tokenId, _data));
    }

    function checkOnIERC721Received(
        address _from,
        address _to,
        uint _tokenId,
        bytes memory data
    ) private returns (bool) {
        if (_to.code.length > 0) {
            try
                IERC721Receiver(_to).onERC721Received(
                    msg.sender,
                    _from,
                    _tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch {
                return false;
            }
        }
         return true;
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "Self approval");
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function _isApprovedOrOwner(address _spender, uint _tokenId) internal view returns(bool) {
        address owner = ownerOf(_tokenId);
        return(_spender == owner || _spender == getApproved(_tokenId) || isApprovedForAll(owner, _spender));
    }

    function getApproved(uint _tokenId) public override view returns(address){
        require(owners[_tokenId] != address(0), "token does not exist");
        return tokenApprovals[_tokenId];
    }

    function safeTransferFrom(address _from, address _to,uint _tokenId) public override {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to,uint _tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender , _tokenId), "NOT APPROVED");
        _safeTransfer(_from, _to, _tokenId, data);
    }

    function mint(address _to, string memory _uri) public {
        uint tokenId = tokenCounter;
        tokenCounter++;
        owners[tokenId] = _to;
        balances[_to] += 1;
        tokenURIs[tokenId] = _uri;

        emit Transfer(address(0), _to, tokenId);
    }

    function tokenURI(uint _tokenId) public view returns(string memory) {
        require(owners[_tokenId] != address(0) ,"token does not exist" );
        return tokenURIs[_tokenId];
    }
}
