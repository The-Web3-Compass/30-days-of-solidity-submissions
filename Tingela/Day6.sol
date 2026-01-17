//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract PayBank {
    address public bankmanager;
    
    address [] members;
    mapping (address => bool) public registeredMembers;

    mapping (address => uint256) balance;

    construct () {
        bankManager = msg.sender;
        members.push(msg.sender);
    }

    //only bank manager

    modifier onlyBankManager()
        require(msg.sender == bankmanager, "Only Bank Manager can perform this Action");
        _;
    }

    //adding new member

function addMembers(address _member) public onlyBankManager {
    require(_member != address(0), "Invalid address");
    require(_member != msg.sender, "Bank Manager is already a member");
    require(!registeredMembers[_member], "Member already registered");

    registeredMembers[_member] = true;
    members.push(_member);
}

function getMembers () public view returns (address [] memory) {
    return members;
}
function deposit(uint256 _amount) public onlyRegisteredMember {
    require(_amount > 0, "Invalid amount");
    balance[msg.sender] += _amount;
}

//withdraw
function withdraw (uint256 _amount) public onlyRegisteredMember {
    require(_amount > 0, "Invalid amount");
    require(balance[msg.sender] >= _amount, "Insufficient banlance");
    balance[msg.sender] -= _amount;

}

function depositAmountEther() public payable onlyRegisteredMember {
    require(msg.value > 0, "Invalid amount");
    balance[msg.sender] += msg.value;
}


}

  
    
