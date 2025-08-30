// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract Ownable {
    address private owner;
    event OwnershipTransferred(address indexed prevOwner, address indexed newOnwer);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorized");
        _;
    }

    function getOwner() public view returns(address){
        return  owner;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "invalid address");
        require(_newOwner != msg.sender, "new owner must be a diff user");

        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

contract VaultMater is Ownable {
    
    event DepositSuccessful(address indexed account, uint value);
    event WithdrawlSuccessful(address indexed receipient, uint value);

    function deposit() public payable onlyOwner {
        require(msg.value > 0, "amount must be grater than 0");

        emit DepositSuccessful(msg.sender, msg.value);
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function withdraw(address _to, uint _amount) public onlyOwner{
        require(_amount > 0, "withdrawl amount must be greater than 0");
        require(_amount <= getBalance(), "itne paise nhi hai tere par");

        (bool success, ) = payable(_to).call{value : _amount}("");
        // OR _to.transfer(_amount)

        require(success, "transfer failed");
        emit WithdrawlSuccessful(_to, _amount);
    }
}
