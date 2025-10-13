// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MyFirstToken
 * @dev Let's make your own digital currency!
 * You'll create a basic token that can be transferred between users, implementing the ERC20 standard.
 * It's like creating your own in-game money, demonstrating how to create and manage tokens.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 12
 */
contract MyFirstToken is ERC20 {
    constructor() ERC20("BguizToken", "BGZ") {
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }
}
