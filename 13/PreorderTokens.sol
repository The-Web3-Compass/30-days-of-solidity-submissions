// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMyFirstToken {
    function transfer(address to, uint amount) external returns(bool);
    function balanceOf(address account) external view returns(uint);
}

contract PreorderTokens {

    address public owner;
    uint public rate;
    IMyFirstToken public token;

    constructor(address _tokenAddress, uint _rate) {
        owner = msg.sender;
        token = IMyFirstToken(_tokenAddress);
        rate = _rate;
    }

    receive() external payable {
        buyTokens();
    }

    function buyTokens() public payable {

        uint tokenAmount = msg.value * rate;

        require(token.balanceOf(address(this)) >= tokenAmount);

        token.transfer(msg.sender, tokenAmount);
    }

    function withdrawEther() public {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }
}