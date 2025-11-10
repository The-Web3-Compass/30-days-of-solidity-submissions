// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./MiniDexPair.sol";

contract MiniDexFactory is Ownable {
    event PairCreated(
        address indexed tokenA,
        address indexed tokenB,
        address pair,
        uint256 index
    );

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    bool public publicCreation = false;

    constructor() Ownable() {}

    function setPublicCreation(bool allow) external onlyOwner {
        publicCreation = allow;
    }

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair)
    {
        require(publicCreation || msg.sender == owner(), "Not allowed");
        require(tokenA != tokenB, "Identical tokens");
        require(tokenA != address(0) && tokenB != address(0), "Zero address");
        require(getPair[tokenA][tokenB] == address(0), "Pair exists");

        (address t0, address t1) =
            tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        pair = address(new MiniDexPair(t0, t1));

        getPair[t0][t1] = pair;
        getPair[t1][t0] = pair;

        allPairs.push(pair);

        emit PairCreated(t0, t1, pair, allPairs.length - 1);
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function getPairAtIndex(uint256 index) external view returns (address) {
        return allPairs[index];
    }
}
