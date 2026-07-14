// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

/**
 * @title SaveMyName
 * @dev Imagine creating a basic profile.
 * You'll make a contract where users can save their name (like 'Alice') and a short bio (like 'I build dApps').
 * You'll learn how to store text (using `string`) on the blockchain.
 * Then, you'll create functions to let users save and retrieve this information.
 * This demonstrates how to store and retrieve data on the blockchain, essential for building profiles or user data storage.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 2
 * ... but modified such that we use mapping and msg.send such that
 * different accounts store separate names and bios.
 */
contract SaveMyNamePerAccount2 {

    mapping(address => string) public names;
    mapping(address => string) public bios;

    function update(string memory newName, string memory newBio) public {
        msg.sender;
        names[msg.sender] = newName;
        bios[msg.sender] = newBio;
    }

    function retrieve() public view returns (string memory name, string memory bio) {
        name = names[msg.sender];
        bio = bios[msg.sender];
    }
}
