// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./MiniDexPair.sol"; // Assumes MiniDexPair.sol is in the same directory

contract MiniDexFactory is Ownable {
    // Emitted when a new token pair is created
    event PairCreated(
        address indexed tokenA,
        address indexed tokenB,
        address pairAddress,
        uint
    );

    // Mapping from tokenA => tokenB => pair address
    mapping(address => mapping(address => address)) public getPair;
    // Array of all pair addresses created
    address[] public allPairs;

    constructor(address _owner) Ownable(_owner) {}

    /**
     * @notice Creates a new MiniDexPair for two tokens.
     * @dev Only the owner can call this.
     * @param _tokenA First token address.
     * @param _tokenB Second token address.
     * @return pair Address of the newly created pair contract.
     */
    function createPair(
        address _tokenA,
        address _tokenB
    ) external onlyOwner returns (address pair) {
        require(
            _tokenA != address(0) && _tokenB != address(0),
            "Invalid token address"
        );
        require(_tokenA != _tokenB, "Identical tokens");
        require(getPair[_tokenA][_tokenB] == address(0), "Pair already exists");

        // Sort tokens to enforce consistent ordering
        (address token0, address token1) = _tokenA < _tokenB
            ? (_tokenA, _tokenB)
            : (_tokenB, _tokenA);

        // Deploy new MiniDexPair contract
        pair = address(new MiniDexPair(token0, token1));
        // Store pair address for both token orderings
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;

        // Track all pairs
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length - 1);
    }

    // Returns total number of pairs created
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    // Get pair address by index
    function getPairAtIndex(uint index) external view returns (address) {
        require(index < allPairs.length, "Index out of bounds");
        return allPairs[index];
    }
}
