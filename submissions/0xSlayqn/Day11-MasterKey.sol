// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

<<<<<<< HEAD

contract Ownable {

=======
contract Ownable {
>>>>>>> 34a5b3e (Day11 - MasterKey.sol)
    address public Owner;

    constructor() {
        Owner = msg.sender;
    }
<<<<<<< HEAD
    
    modifier onlyOwner ()  {
=======

    modifier onlyOwner() {
>>>>>>> 34a5b3e (Day11 - MasterKey.sol)
        require(Owner == msg.sender, "Not a owner");
        _;
    }

<<<<<<< HEAD
    function transferOwnership(address _newOwner) public onlyOwner() {
        require(_newOwner != address(0), "Not a valid address");
        Owner = _newOwner;
    }

}

contract VaultMaster is Ownable {

    function withdraw(uint _amount) public onlyOwner {
    require(_amount <= address(this).balance, "Insufficient balance");
    payable(msg.sender).transfer(_amount);
    }

    receive() external payable { }

=======
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Not a valid address");
        Owner = _newOwner;
    }
}

contract VaultMaster is Ownable {
    function withdraw(uint _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
        payable(msg.sender).transfer(_amount);
    }

    receive() external payable {}
>>>>>>> 34a5b3e (Day11 - MasterKey.sol)
}
