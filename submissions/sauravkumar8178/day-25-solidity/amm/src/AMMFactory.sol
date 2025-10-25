// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./AMMPair.sol";

contract AMMFactory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    event PairCreated(address indexed token0, address indexed token1, address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "AMMFactory: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "AMMFactory: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "AMMFactory: PAIR_EXISTS");
        AMMPair newPair = new AMMPair(token0, token1);
        pair = address(newPair);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair);
    }
}
