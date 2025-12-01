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
 */
contract SaveMyName {
    string public name = "";
    string public bio = "";

    function update(string memory newName, string memory newBio) public {
        name = newName;
        bio = newBio;
    }
}
