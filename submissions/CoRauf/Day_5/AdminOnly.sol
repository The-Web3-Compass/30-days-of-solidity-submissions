//SPDX-License-Identifer :MIT

pragma solidity ^0.8.18;

contract Treasure_Chest{

    address public owner;
    uint256 public treasure_amount;
    mapping (address => bool) public allowance;

    
    constructor() {
        owner = msg.sender;
    }

    modifier owned(){
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function add_treasure() public payable owned{
       treasure_amount = msg.value;
    }

    function approve_Withdrawal(address _user) public owned{
        allowance[_user] = true;
    }

    function withdrawal() public {
        require(allowance[msg.sender] == true, "Owner has not approve withdrawal");
        require(treasure_amount >= 1 ether, "Not enough Treasure");

        allowance[msg.sender] = false;
        (bool ok, ) = payable(msg.sender).call{value : 1 ether}("");
        require(ok, "Transfer failled");
    }

    function transfer_ownership(address _newOwner) public owned{
        owner = _newOwner;
    }

    function check_allowance() public view returns(bool){
        return allowance[msg.sender];
    }

}