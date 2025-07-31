// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;


contract EtherPiggyBank {
    error Invalid__Amount();
    address public  manager; 



    mapping(address customer => uint256 amount) public  balances;


modifier  onlyOwner(){
    if(msg.sender != manager){
        revert("You are not a manager");
    }
    _;
}

    constructor(){
        manager = msg.sender;
    }





    function Deposit() public payable {
        if(msg.value ==0){
            revert Invalid__Amount();
        }
        balances[msg.sender] += msg.value;
    }
 

    function Withdraw(address payable  _customer , uint256 _amount) public {

        if(_amount > balances[msg.sender]){
            revert ("Not Enough Fund" );
        }

        balances[msg.sender] -= _amount;
        _customer.transfer(_amount);

}


function getCustomerBalance()public  view returns(uint256){
    return balances[msg.sender];
}

function getTotalDeposit() public view  onlyOwner returns(uint256){
    if(address(this).balance == 0){
        revert("No Deposits");
    }
    uint256 totalDeposit = address(this).balance;
    return totalDeposit;
}

}