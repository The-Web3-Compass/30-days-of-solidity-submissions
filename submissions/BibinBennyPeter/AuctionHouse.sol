// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
contract AuctionHouse {

    struct item{
        string name;
        uint price;
        uint timeInSeconds;
        address payable  owner;
        address payable tokenAddress;
        TokenType tokenType;
        uint256[] tokenIds;
        uint256[] amounts;
        bytes data;
    }

    enum TokenType { ERC721, ERC1155, ERC20 }
    item[] public items;

    mapping (uint => address) public itemToBidder;

    address public immutable seller;

    constructor (){
        seller = msg.sender;
    }

    function addItem(string memory _name, uint256 _price, uint256 _timeInSeconds,address payable _owner, address payable  _tokenAddress, TokenType _tokenType) external {
        items.push(item(_name,_price,_timeInSeconds,_owner, _tokenAddress, _tokenType, new uint256[](0), new uint256[](0), bytes("")));
    }

    function addItem(string memory _name, uint256 _price, uint256 _timeInSeconds,address payable _owner, address payable  _tokenAddress, TokenType _tokenType, uint256 _tokenId) external {
        uint256[] memory tokenIds;
        tokenIds[0] = _tokenId;
        items.push(item(_name,_price,_timeInSeconds,_owner, _tokenAddress, _tokenType, tokenIds, new uint256[](0), bytes("")));
    }

    function addItem(string memory _name, uint256 _price, uint256 _timeInSeconds,address payable _owner, address payable  _tokenAddress, TokenType _tokenType, uint256[] memory _tokenIds, uint256[] memory _amounts, bytes memory data) external {
        items.push(item(_name,_price,_timeInSeconds,_owner, _tokenAddress, _tokenType, _tokenIds, _amounts, data));
    }

    function bid(uint256 _id) external payable {
        require(msg.value > items[_id].price, "Your bid is lower than the price");
        itemToBidder[_id] = msg.sender;
        items[_id].price = msg.value;
    }

    function getItem( uint256 _id) external {
        require(itemToBidder[_id] != address(0),"No bid exists for this item");
        require(msg.sender == itemToBidder[_id] || msg.sender == seller,"Caller should either be the bidder or the seller");
        require(block.timestamp > items[_id].timeInSeconds,"Auction hasn't ended");
        if (items[_id].tokenType == TokenType.ERC20){
            IERC20(items[_id].tokenAddress).transferFrom(items[_id].owner, itemToBidder[_id], items[_id].price);
        }
        else if (items[_id].tokenType == TokenType.ERC721){
            IERC721(items[_id].tokenAddress).safeTransferFrom(items[_id].owner, itemToBidder[_id], items[_id].tokenIds[0]);
        }
        else {
            IERC1155(items[_id].tokenAddress).safeBatchTransferFrom(items[_id].owner, itemToBidder[_id], items[_id].tokenIds, items[_id].amounts, items[_id].data);
        }
        (items[_id].owner).transfer(items[_id].price);
    }
}
