//SPDX-License-Identifer: MIT

pragma solidity ^0.8.18;

contract Token{

    address public owner;
    mapping(address => uint256) public balanceOf;

    function deposit() public payable {
        balanceOf[msg.sender] = msg.value;
    }

    function transfer(address _to, uint256 _amount) public {
        require(balanceOf[msg.sender] > 0);
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] =  balanceOf[_to] + _amount;
    }

    function withdraw() public {
        require(balanceOf[msg.sender] >= 1 ether, "Not enough ETH");

        uint256 amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        (ok, "ETH not sent");
    }

    function getBalance() public view returns(uint256){
        return balanceOf[msg.sender];
    }
}