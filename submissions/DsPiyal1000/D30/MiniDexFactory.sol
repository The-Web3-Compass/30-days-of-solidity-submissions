// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./MiniDexPair.sol";

contract MiniDexFactory is Ownable {

    error InvalidTokenAddress();
    error IdenticalTokens();
    error PairAlreadyExists();
    error IndexOutOfBounds();

    event PairCreated(address indexed tokenA, address indexed tokenB, address pairAddress, uint256 indexed pairIndex);

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    constructor(address _owner) Ownable(_owner) {}

    function createPair(address _tokenA, address _tokenB) external onlyOwner returns (address pair) {
        if (_tokenA == address(0) || _tokenB == address(0)) revert InvalidTokenAddress();
        if (_tokenA == _tokenB) revert IdenticalTokens();

        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);

        if (getPair[token0][token1] != address(0)) revert PairAlreadyExists();

        pair = address(new MiniDexPair(token0, token1));

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;

        allPairs.push(pair);
        uint256 pairIndex = allPairs.length - 1;

        emit PairCreated(token0, token1, pair, pairIndex);
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function getPairAtIndex(uint256 index) external view returns (address) {
        if (index >= allPairs.length) revert IndexOutOfBounds();
        return allPairs[index];
    }

    function findPair(address tokenA, address tokenB) external view returns (address) {
        return getPair[tokenA][tokenB];
    }
}