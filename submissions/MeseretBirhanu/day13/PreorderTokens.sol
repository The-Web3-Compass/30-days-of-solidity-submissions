// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../day12/AthenaToken.sol";


contract PreorderTokens{
     AthenaToken public tokenContract;
     uint256 public  tokenPerEth = 100;
     address public owner;

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);

    constructor(address _addrsContract){
        tokenContract = AthenaToken(_addrsContract);
        owner = msg.sender;
    }

    function buy() public payable {
       require(msg.value > 0, "you need to send ETH to buy tokens");

       uint256 amountToBuy = msg.value * tokenPerEth;
       uint256 vendorBalance = tokenContract.balanceOf(address(this));
    require(vendorBalance >= amountToBuy, "Vendor has insufficient tokens");

    bool sent = tokenContract.transfer(msg.sender, amountToBuy);
        require(sent, "transfer failed");

emit BuyTokens(msg.sender, msg.value, amountToBuy);
    } 

    function withdraw() public payable  {
        require(msg.sender == owner, "Only owner");
        (bool success ,) = owner.call{value:address(this).balance}('');
        require(success , "failed to withdraw");
    }
    
}

// token address for anyone who want to try it 0x891398D7EB2F5ec811dAaAC17EaEaCb5e711F5Cc
