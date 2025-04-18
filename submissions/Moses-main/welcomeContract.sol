// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

✨ Welcome to 30 Days of Solidity ✨
------------------------------------------
You just deployed your very first contract.
Are you a Web3 wizard now? Technically, yes.

This contract won’t launch rockets,
but it *will* launch your dev journey 🚀

Let’s goooo!

*/

contract DayZeroWelcome {
    string public message;
    uint256 public vibeScore;

    constructor() {
        message = "Hey frens You just summoned a contract out of thin air. Kinda magical, ngl.";
        vibeScore = 100; // Starting with max vibes
    }

    function boostMorale() public returns (string memory) {
        vibeScore += 1;
        return " Vibe boosted! You're doing amazing sweetie.";
    }

    function whoAmI() public pure returns (string memory) {
        return "You're a Solidity dev now. Wear it like a hoodie.";
    }

    function updateMessage(string calldata newMessage) public {
        message = newMessage;
    }
}
