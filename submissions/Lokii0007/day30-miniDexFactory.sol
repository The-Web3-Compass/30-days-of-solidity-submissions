// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "./day30-miniDexPair.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract miniDexFactory is Ownable {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(
        address indexed tokenA,
        address indexed tokenB,
        address pairAddress,
        uint
    );

    constructor(address _owner) Ownable(_owner) {}

    function createPair(address _tokenA, address _tokenB) external onlyOwner returns(address pair) {
        require(_tokenA != _tokenB, "identical tokens");
        require(
            _tokenA != address(0) && _tokenB != address(0),
            "invalid tokens"
        );
        require(getPair[_tokenA][_tokenB] == address(0), "token already exist");

        (address token0, address token1) = _tokenA < _tokenB
            ? (_tokenA, _tokenB)
            : (_tokenB, _tokenA);
        pair = address(new MiniDex(token0, token1));
        getPair[token1][token0] = pair;
        getPair[token0][token1] = pair;

        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length - 1);
    }

    //! why compare tokens

    function allPairsLength() external view returns(uint){
        return allPairs.length;
    }

    function getPairAtIndex(uint _index) external view returns(address){
        require(allPairs.length < _index, "pair index out of bounds");
        return allPairs[_index];
    }
}
