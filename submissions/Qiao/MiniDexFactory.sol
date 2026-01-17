 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./MiniDexPair.sol";

contract MiniDexFactory is Ownable {
    mapping(address => mapping(address => address)) public pairLookup;
    address[] public allPairs;

    event PairCreated(address indexed tokenA, address indexed tokenB, address pairAddress, uint);

    constructor(address _owner) Ownable(_owner) {}

    function createPair(address _tokenA, address _tokenB) external onlyOwner returns (address pairAddress) {
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token(s).");
        require(_tokenA != _tokenB, "Identical tokens");
        require(pairLookup[_tokenA][_tokenB] == address(0), "Pair already exists");

        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        pairAddress = address(new MiniDexPair(token0, token1));
        pairLookup[token0][token1] = pairAddress;
        pairLookup[token1][token0] = pairAddress;

        allPairs.push(pairAddress);

        emit PairCreated(_tokenA, _tokenB, pairAddress, allPairs.length - 1);
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function getPairAtIndex(uint index) external view returns (address) {
        require(index > 0 && index < allPairs.length, "Invalid index.");
        return allPairs[index];
    }
}

