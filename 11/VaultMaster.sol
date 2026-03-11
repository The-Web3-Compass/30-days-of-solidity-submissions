// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract VaultMaster is Ownable {

    receive() external payable {}

    function withdraw(uint amount) public onlyOwner {
        require(address(this).balance >= amount);
        payable(owner).transfer(amount);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
}