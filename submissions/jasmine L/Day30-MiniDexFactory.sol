// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Day30-MiniDexPair.sol";

contract MiniDexFactory is Ownable{
    mapping (address  => mapping (address => address)) public getPair;//是否存在兑换合约
    //如果节省空间可以进行压缩存储节省一半的存储空间（未知是否可以用在不确定数组长度的？不可以，因为不是数组

    address[] public allPairs; //存储所有配对合约

    event PairCreated(address indexed tokenA, address indexed tokenB, address pairAddress, uint);//此处uint指的是交换合约的索引
    
    constructor(address _owner) Ownable(_owner){}

    function createPair(address _tokenA, address _tokenB) external onlyOwner returns(address pair){
        require(_tokenA != address(0) && _tokenB != address(0), "Invaild token address");
        require(_tokenA != _tokenB, "Identical address");
        require(getPair[_tokenA][_tokenB] == address(0), "Pair already exists");

        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);

        pair = address(new MiniDexPair(token0, token1, "Liquidity Pool Token","LPT"));
        
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length-1);

    }

    function allPaireLength() external  view returns (uint){
        return allPairs.length;
    }

    function getPairAtIndex(uint index) external view returns(address){
        require(index < allPairs.length, "Index out of bounds");
        return allPairs[index];
    }



}