// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {MyFirstToken} from "../Day_12/MyFirstToken.sol";

contract PreorderTokens is MyFirstToken {
    error MyFirstToken_TooManyForPresale();
    
    uint256 tokenPrice;
    uint256 tokenSold;
    uint256 MaxTokensToSell;

    address private owner;

    constructor(string memory _name, string memory _symbol)  MyFirstToken(_name, _symbol) {
        owner = msg.sender;
    }

    function setMaxTokensToSell(uint256 _MaxTokensToSell) external virtual returns (bool success) {
    // Ensure at least 10% of tokens are NOT available for pre-sale
    if (_MaxTokensToSell > (tokenSupply * 9) / 10) {
        revert MyFirstToken_TooManyForPresale();
    } else {
        MaxTokensToSell = _MaxTokensToSell; 
        return true;
    }
}

    

}