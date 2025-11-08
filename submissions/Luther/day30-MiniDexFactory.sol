//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./day30-MiniDexPair.sol";

contract MiniDexFactory is Ownable {
    //定义事件，用于记录每次成功创建新交易对的详细信息
    event PairCreated(address indexed tokenA, address indexed tokenB, address pairAddress, uint);

    //定义双层映射：通过 tokenA 和 tokenB 地址找到对应的交易对合约地址
    mapping(address => mapping(address => address)) public getPair;
    //存储所有已创建的交易对地址列表
    address[] public allPairs;

    //构造函数，调用 Ownable 合约的构造函数初始化所有者
    constructor(address _owner) Ownable(_owner) {}

    //定义一个公开函数，由合约所有者调用，用来创建新的交易对
    function createPair(address _tokenA, address _tokenB) external onlyOwner returns (address pair) {
        //检查输入代币地址是否有效（不能为零地址）
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token address");
        //确保两种代币不是同一个
        require(_tokenA != _tokenB, "Identical tokens");
        //检查该代币对是否已经存在
        require(getPair[_tokenA][_tokenB] == address(0), "Pair already exists");

        //按地址大小排序代币，使每个 pair 的顺序固定
        //避免 (A,B) 与 (B,A) 被视为两个不同的组合
        (address token0, address token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);

        //创建一个新的 MiniDexPair 合约实例，并返回它的地址
        pair = address(new MiniDexPair(token0, token1));

        //把该 pair 地址记录进映射中（双向）
        //方便之后用任意顺序查询交易对
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;

        //将新创建的交易对地址添加进列表
        allPairs.push(pair);
        //触发事件，记录交易对的创建情况
        emit PairCreated(token0, token1, pair, allPairs.length - 1);
    }

    //定义只读函数，用来查询当前所有交易对数量
    function allPairsLength() external view returns (uint) {
        //返回数组长度
        return allPairs.length;
    }

    //通过索引返回特定交易对地址
    function getPairAtIndex(uint index) external view returns (address) {
        //检查索引是否越界
        require(index < allPairs.length, "Index out of bounds");
        //返回对应索引的交易对地址
        return allPairs[index];
    }
}
