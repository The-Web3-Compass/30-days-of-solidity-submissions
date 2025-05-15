// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approvred, uint indexed tokenId);
    event ApprovedForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns(uint);
    function ownerOf(uint tokenId) external view returns(address);
    
    function approve(address to, uint tokenId) external;
    function getApproved(uint tokenId) external view returns(address);

    function setApprovalForAll(address operator, bool approved) external;
    function isApproved2aForAll(address owner, address operator) external view returns(bool);

    function transferFrom(address from , address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata data) external;
    
}

interface IERC721Received {
    function onIERC721Recieved(address operator, address from, uint tokenId, bytes calldata data) external returns(bytes4);
}

contract simpleNFT is IERC721 {
    string public name;
    string public symbol;

    uint private tokenCounter = 1;

    mapping(uint => address) private owners;
    mapping(address => uint) private balances;
    mapping(uint => address) private tokenApprovals;
    mapping(address => mapping(address => bool)) private operatorApprovals; 
    mapping(uint => string) private tokenURIs;

    constructor(string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address _owner) public override view returns(uint){
        require(_owner != address(0), "invalid/xero address");
        return balances[_owner];
    }

    function ownerOf(uint _tokenId) public override view returns(address) {
        address owner = owners[_tokenId];
        require(owner != 0 , "token deos not exist");

        return owner;
    }

    function approve(address to , uint _tokenId) public override {
        address owner = ownerOf(_tokenId);

        require(owner != 0 , "token deos not exist");
        require(owner != msg.sender || isApprovedForAll(owner, msg.sender) , "not authorized");
        
        tokenApprovals[_tokenId] = to;
        emit Approval(owner, to, _tokenId);
    }
}