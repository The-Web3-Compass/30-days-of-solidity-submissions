//SPDX-License-Identifer : MIT
pragma solidity ^0.8.18;

contract PiggyBank{

    mapping (address => uint256) public userBalance;

    function deposit() external payable{
        userBalance[msg.sender] = msg.value;
    }

    receive() external payable{}

    function withdraw() public {
        uint256 amount;
        amount = userBalance[msg.sender];
        userBalance[msg.sender] = 0;
        require(amount >= 1 ether, "Not enough ETH");

        (bool ok, ) = payable(msg.sender).call{value : amount}("");
        require(ok, "ETH not sent");
    }

    function getBalance() public view returns(uint256){
        return userBalance[msg.sender];
    }

}