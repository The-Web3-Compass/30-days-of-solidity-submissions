// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly{
    address public owner;
    uint256 goldAmount;
    mapping(address => uint256) public goldAllowance;

    constructor(uint256 _goldAmount){
        owner = msg.sender;
        goldAmount = _goldAmount;
    }

    modifier OnlyOwner(){
        require(owner == msg.sender,"U not the owner!!");
        _;
    }

    function addGold(uint256 _amount) public OnlyOwner{
        goldAmount += _amount;
    }

    function Distribution(address _addr,uint256 _amount) public OnlyOwner{
        require(_amount < goldAmount,"Too much!!");
        goldAllowance[_addr] = _amount;
    }

    function Withdraw(uint256 _amount) public {
        if(owner == msg.sender){
            require(_amount < goldAmount,"Too much!!");
            goldAmount -= _amount;
        }
        else{
            require(_amount < goldAllowance[msg.sender],"Too much!!");
            goldAllowance[msg.sender] -= _amount;
            goldAmount -= _amount;
        }
    }

    function TransferOwnership(address _addr) public OnlyOwner{
        owner = _addr;
    }

    function CheckGoldAmount() public view returns(uint256){
        return goldAmount;
    }
}