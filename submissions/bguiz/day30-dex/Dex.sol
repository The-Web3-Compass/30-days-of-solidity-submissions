// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { AmmLp } from "./AmmLp.sol";

/**
 * @title Dex
 * @dev Build a simple exchange for trading tokens.
 * You'll learn how to create a digital marketplace using token swaps and liquidity pools.
 * It's like a mini version of a stock exchange, demonstrating how to create decentralized exchanges.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 30
 */
contract Dex is Ownable, ReentrancyGuard {
    mapping(IERC20Metadata => mapping(IERC20Metadata => AmmLp)) public lps;

    constructor() Ownable(msg.sender) {}

    function getLp(
        IERC20Metadata tokenA,
        IERC20Metadata tokenB
    ) public view returns(AmmLp) {
        AmmLp lp1 = lps[tokenA][tokenB];
        if (address(lp1) != address(0x00)) {
            return lp1;
        }
        AmmLp lp2 = lps[tokenB][tokenA];
        return lp2; // whether or not it exists
    }

    function addLp(
        IERC20Metadata tokenA,
        IERC20Metadata tokenB,
        uint256 swapFee
    ) public nonReentrant returns(AmmLp newLp) {
        require(swapFee > 0, "swap fee must be more than zero");
        AmmLp existingLp = getLp(tokenA, tokenB);
        require(address(existingLp) != address(0x00), "liquidity pool already exists");
        newLp = new AmmLp(
            string.concat("AMM LP: ", tokenA.symbol(), "-", tokenB.symbol()),
            string.concat("ammlp_", tokenA.symbol(), "_", tokenB.symbol()),
            tokenA,
            tokenB,
            swapFee
        );
    }

    function removeLp (
        IERC20Metadata tokenA,
        IERC20Metadata tokenB
    ) public onlyOwner nonReentrant {
        delete lps[tokenA][tokenB];
        delete lps[tokenB][tokenA];
    }
}
