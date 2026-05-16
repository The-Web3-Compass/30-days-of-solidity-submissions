// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MiniDexPair.sol";

contract MiniDexFactory {
    // Mapping from TokenA -> TokenB -> Pair address
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "Identical addresses");
        require(tokenA != address(0) && tokenB != address(0), "Zero address");
        require(getPair[tokenA][tokenB] == address(0), "Pair already exists");

        //Sort tokens so token0 < token1 (avoids duplicates  like A-B and B-A)
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

// Deploy!
        // Note: In real production we use create2 for deterministic addresses, 
        // but 'new' keyword is fine for our tutorial.

MiniDexPair newPair = new MiniDexPair(token0, token1);
pair = address(newPair);

getPair[token0][token1] = pair;
getPair[token1][token0] = pair; // Populate reverse mapping
allPairs.push(pair);

emit PairCreated(token0, token1, pair, allPairs.Length);
    }
}