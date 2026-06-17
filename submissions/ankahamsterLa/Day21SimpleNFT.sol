//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

// NFT:
// - It is about digital ownership on blockchain and it is Non-Fungible Token which means that it's not interchangeable and it is unique.

// ERC20 token:it is a fungible token and it's equal and interchangeable.
// NFTs: built in ERC-721 standard, each token has its own identity.

// In this contract, build a first NFT contract which follows ERC-721 standard.
    // Give users' NFT collection a name and symbol;
    // Lets you mint new NFTs with custom metadata;
    // Tracks who owns what;
    // Keeps track of how many NFTs each person owns;
    // Lets owner approve others to transfer their NFT;
    // Handles transfers between users.


// This is the ERC-721 interface, which defines all the mandatory functions and events an NFT contract must implement to be called "ERC-721 compliant".
// Functions in this contract handle ownership,approvals and transferring tokens.
interface IERC721{
    event Transfer(address indexed from,address indexed to,uint256 indexed tokenId);
    event Approval(address indexed owner,address indexed approved,uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator,bool approved);

    function balanceOf(address owner) external view returns(uint256);
    function ownerOf(uint256 tokenId) external view returns(address);
    
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns(address);

    function setApprovalForAll(address operator,bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns(bool);

    function transferFrom(address from, address to, uint256 tokenId)external;
    function safeTransferFrom(address from, address to,uint256 tokenId) external;
    function safeTransferFrom(address from,address to, uint256 tokenId,bytes calldata data) external;

}

// This interface is used to safely send NFTs to contracts.
// If you try to transfer an NFT to a smart contract that can't handle it, the NFT might get stuck. So we check that the receiving contract knows what to do with an NFT.
interface IERC721Receiver{
        function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata data) external returns(bytes4);
}

// This contract promise to include all the functions defined inside the IERC721 interface.
contract SimpleNFT is IERC721{
    string public name;
    string public symbol;

    // Use token ID to mark every unique NFT.
    uint256 private _tokenIdCounter=1; // Tracks the next available token ID to mint.

    mapping(uint256=>address) private _owners; // token ID => address of owner
    mapping(address=>uint256) private _balances;// address of owner => amount of tokens
    mapping(uint256=>address) private _tokenApprovals;// token ID => address of owner who is approved to transfer this token
    mapping(address=>mapping(address=>bool)) private _operatorApprovals;// address of initial owner=>address of owner approved to be transferred=>bool approval
    mapping(uint256=>string) private _tokenURIs;// token ID=>metadata URL for each token

    constructor(string memory name_,string memory symbol_){
        name=name_;
        symbol=symbol_;
    }

    function balanceOf(address owner) public view override returns(uint256){
        require(owner!=address(0),"Zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns(address){
        address owner=_owners[tokenId];
        require(owner!=address(0),"Token doesn't exist");
        return owner;
    }

    // "msg.sender" is giving this specific person("address to") permission to transfer this specific token.
    function approve(address to, uint256 tokenId) public override{
        address owner=ownerOf(tokenId);
        require(to!=owner,"Already owner");
        // Owner can approve someone or an operator(someone pre-approved to manage all tokens) can approve someone
        require(msg.sender==owner|| isApprovedForAll(owner,msg.sender),"Not authorized");

        _tokenApprovals[tokenId]=to;
        // address of initial owner,address of owner approved to be transferred,token ID
        emit Approval(owner,to,tokenId);

    }
    
    // Check who is approved to transfer a specific token
    function getApproved(uint256 tokenId) public view override returns(address){
        require(_owners[tokenId]!=address(0),"Token doesn't exist");
        return _tokenApprovals[tokenId];

    }

    function setApprovalForAll(address operator, bool approved) public override{
        require(operator!=msg.sender,"Self approval");
        // Users approve or revoke access to all NFTs for a given operator(like a marketplace or vault contract).
        _operatorApprovals[msg.sender][operator]=approved;
        emit ApprovalForAll(msg.sender,operator,approved);

    }

    // Check if an operator is approved to manage all NFTs owned by someone.
    function isApprovedForAll(address owner,address operator) public view override returns(bool){
        return _operatorApprovals[owner][operator];

    }

    function transferFrom(address from, address to, uint256 tokenId) public override{
        require(_isApprovedOrOwner(msg.sender,tokenId),"Not authorized");
        _transfer(from, to,tokenId);

    }

    // Basic version of safe transfer
    // Delegate it to the next version(the one with the "bytes memory data"),passing in an empty data payload.
    function safeTransferFrom(address from, address to, uint256 tokenId) public override{
        safeTransferFrom(from,to,tokenId,"");

    }

    
    function safeTransferFrom(address from, address to, uint256 tokenId,bytes memory data) public override{
        require(_isApprovedOrOwner(msg.sender,tokenId),"Not authorized");
        _safeTransfer(from,to,tokenId,data);
    }

    // Minting functions for creating new NFTs.
    // It allows to assign it a unique tokenId, give ownership to the recipient, store its metadata URI and emit a "transfer" from the zero address.
    function mint(address to,string memory uri) public{
        uint256 tokenId=_tokenIdCounter;
        _tokenIdCounter++;

        _owners[tokenId]=to;
        _balances[to]+=1;
        _tokenURIs[tokenId]=uri;

        emit Transfer(address(0),to,tokenId);// emit a "transfer" from the zero address
    }


    function tokenURI(uint256 tokenId) public view returns(string memory){
        require(_owners[tokenId]!=address(0),"Token doesn't exist");
        return _tokenURIs[tokenId];

    }

    // Core funciton that handles the actual movement of an NFT from one wallet to another.
    // Transfer the ownership from address from to address to.
    function _transfer(address from, address to,uint256 tokenId) internal virtual{
        require(ownerOf(tokenId)==from,"Not owner");
        require(to!=address(0),"Zero address");

        _balances[from]-=1;
        _balances[to]+=1;
        _owners[tokenId]=to;

        delete _tokenApprovals[tokenId];
        emit Transfer(from,to,tokenId);

    }

    // Based on the _transfer function, this function add one crucial check which help avoid sending NFTs to smart contracts of being not able to handle NFTs by callng "_checkOnERC721Received" after the transfer.
    function _safeTransfer(address from,address to,uint256 tokenId, bytes memory data) internal virtual{
        _transfer(from,to,tokenId);
        require(_checkOnERC721Received(from,to,tokenId,data),"Not ERC721Receiver");

    }

    // Check if the function caller is allowed to move this token.
    function _isApprovedOrOwner(address spender,uint256 tokenId) internal view returns(bool){
        address owner=ownerOf(tokenId);
        return(spender==owner||getApproved(tokenId)==spender||isApprovedForAll(owner,spender));
    }

    // Safety check used by "_safeTransfer".
    // try / catchSafe external call – if it fails, go to catch instead of reverting entire tx
    // like try-else structure in python
    function _checkOnERC721Received(address from,address to,uint256 tokenId,bytes memory data) private returns(bool){
        // It checks if it is a smart contract. Wallet address have no code, but contracts do.
        if(to.code.length>0){
            // try ("executing funtion")
            // Use standard fist 4 bytes value to check if it can safely receive NFTs.
            try IERC721Receiver(to).onERC721Received(msg.sender,from,tokenId,data) returns (bytes4 retval){
                // selector is the first 4 bytes "keccak256("onERC721Received(address,address,uint256,bytes)")"
                // Compare the value of retval and selector and return the bool result to function "_checkOnERC721Received"
                return retval==IERC721Receiver.onERC721Received.selector;
            }
            // If it can not safely receive NFTs:
            catch{
                return false;
            }
        }
        return true;

    }

}
