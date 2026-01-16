// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MiniDexPair is ReentrancyGuard , ERC20{ //ERC20可以直接用函数
    
    //address public immutable tokenA;
    //address public immutable tokenB;
    //只需要与外部代币交互，不需要实现，所以用IERC20：只定义规则，不包含实现
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    //address public owner;

    uint256 public reserveA;
    uint256 public reserveB;
    //uint256 public totalSupply;//LP代币总量

    //添加流动性，获得了多少LP代币
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    // 移除流动性，销毁了多少LP代币
    event LiquidityRemoved(address indexed provider,  uint256 amountA, uint256 amountB, uint256 liquidity);
    // 兑换代币
    event Tokenswapped(address indexed trader, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    //mapping (address => uint256) public lpBalances;


    constructor(address _tokenA, address _tokenB,  string memory _name, string memory _symbol)ERC20(_name,_symbol){
        tokenA = ERC20(_tokenA);//此处只是类型转换，tokenA的变量类型并没有转换
        tokenB = ERC20(_tokenB);
    }

    // 实用工具
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external nonReentrant{
        require(amountA >0 && amountB >0, "All amounts must be > 0 ");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        
        uint256 liquidity;
        if(totalSupply() == 0){
            liquidity = sqrt(amountA*amountB);
        }else{
            // 希望维持当前价格比例
            liquidity = min(amountA * totalSupply()/reserveA, amountB*totalSupply()/reserveB);
            //此处没有吧多余的某一种币退回去
        }
        _mint(msg.sender, liquidity);
        //计算LP铸造的时候，还没有把新的加进来
        reserveA += amountA;
        reserveB += amountB;
        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }
    

    function removeLiquidity(uint256 LiquidityToRemove) external nonReentrant returns (uint256 amountAOut, uint256 amountBOut){
        require(LiquidityToRemove > 0, "must be > 0 ");
        require(balanceOf(msg.sender) >= LiquidityToRemove, "Insufficient liquidity tokens");
        uint256 totalLiquidity = totalSupply();
        require(totalLiquidity > 0, "No liquidity in the pool");

        amountAOut = LiquidityToRemove * reserveA / totalLiquidity;
        amountBOut = LiquidityToRemove * reserveB / totalLiquidity;

        // 防止计算因四舍五入出现灰尘值，如果任何输出为 0，则拒绝交易 —— 避免出错或浪费提款
        require(amountAOut > 0 && amountBOut > 0, "Insufficient reserves for requested liquidity");
        reserveA -= amountAOut;
        reserveB -= amountBOut;
        _burn(msg.sender, LiquidityToRemove);
        tokenA.transfer(msg.sender, amountAOut);
        tokenB.transfer(msg.sender, amountBOut);

        emit LiquidityRemoved(msg.sender, amountAOut, amountBOut, LiquidityToRemove);
        return (amountAOut, amountBOut);
    }

    function swapAforB(uint256 amountAIn, uint256 minBOut)external nonReentrant {
        require(amountAIn>0, "must be > 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

        uint256 amountAInWithFee = amountAIn * 997 / 1000; //扣除相应手续费的tokenA
        uint256 amountBOut = reserveB * amountAInWithFee / ( reserveA + amountAInWithFee);//经过公式简化而来

        require(amountBOut >= minBOut, "Slippage too high");//没有达到我想换的钱我就不换了！！

        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        reserveA += amountAInWithFee;
        reserveB -= amountBOut;
        emit Tokenswapped(msg.sender, address(tokenA), amountAIn, address(tokenB), amountBOut);
    }

    function swapBforA(uint256 amountBIn, uint256 minAOut)external nonReentrant{
        require(amountBIn>0, "must be > 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

        uint256 amountBInWithFee = amountBIn * 997 / 1000; //扣除相应手续费的tokenA
        uint256 amountAOut = reserveA * amountBInWithFee / ( reserveB + amountBInWithFee);//经过公式简化而来

        require(amountAOut >= minAOut, "Slippage too high");//没有达到我想换的钱我就不换了！！

        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);

        reserveB += amountBInWithFee;
        reserveA -= amountAOut;
        emit Tokenswapped(msg.sender, address(tokenB), amountBIn, address(tokenA), amountAOut);

    }
    function getReserves()external view returns(uint256,uint256){
        return(reserveA,reserveB);
    }

    function getLPBalance(address user) external view returns (uint256) {
        return balanceOf(user);
    }

    function getTotalLPSupply() external view returns (uint256) {
        return totalSupply();
    }   


}