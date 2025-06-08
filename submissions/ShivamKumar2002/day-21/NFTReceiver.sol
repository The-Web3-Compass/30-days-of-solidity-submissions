// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721.sol";

contract NFTReceiver is ERC721TokenReceiver {
    /// @inheritdoc ERC721TokenReceiver
    function onERC721Received(address /*_operator*/, address /*_from*/, uint256 /*_tokenId*/, bytes memory /*_data*/) external pure returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}