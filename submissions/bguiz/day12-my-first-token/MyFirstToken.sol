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
    constructor(uint256 initialSupply) ERC20("BguizToken", "BGZ") {
        _mint(msg.sender, initialSupply);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }
}

/*
addresses
0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
*/
