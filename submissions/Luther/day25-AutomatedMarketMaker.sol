//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//导入ERC20合约，使本合约可以 is ERC20 继承并使用 totalSupply(), _mint, _burn, balanceOf, 等函数
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//定义合约名并继承 OpenZeppelin 的 ERC20，用于表示池的流动性代币 — LP token
contract AutomatedMarketMaker is ERC20 {
    //声明两个外部代币合约的接口引用（A 和 B）
    IERC20 public tokenA;
    IERC20 public tokenB;

    //在合约内部记录“池中”A/B 代币的储备量
    uint256 public reserveA;
    uint256 public reserveB;

    //合约拥有着地址（在构造函数中设好滋味）
    address public owner;

    //LiquidityAdded：记录谁添加了多少代币流动性
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    //这个事件在移除流动性时触发（removeLiquidity()）
    //LiquidityRemoved：记录谁取出了多少代币流动性
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    //这是在用户**进行代币兑换（swap）**时触发的事件
    //TokensSwapped：记录谁用什么代币换了什么代币
    event TokensSwapped(address indexed trader, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    //构造函数会在合约部署时调用
    //ERC20(_name, _symbol) 是对父合约构造器的传参
    //表示 LP 代币会用 _name、_symbol 初始化
    constructor(address _tokenA, address _tokenB, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        //将传入的地址转换为 IERC20 类型并存储
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        //将创建者（部署交易的发送者）设为 owner
        owner = msg.sender;
    }

    //addLiquidity 函数（添加流动性）
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        //输入校验：两种代币数量都必须大于 0，否则交易回滚并返回错误信息
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");

        //从调用者地址把 amountA / amountB 的代币转到合约地址
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        //如果池子还没有 LP 代币（即这是第一个添加流动性的提供者）
        //合约按 sqrt(amountA * amountB) 计算要 mint 的 LP 代币数量
        uint256 liquidity;
        if (totalSupply() == 0) {
            liquidity = sqrt(amountA * amountB);
        //如果已有流动性，新的 LP token 数量由两种代币中限制性那一侧按现有比例计算
        } else {
            liquidity = min(
                amountA * totalSupply() / reserveA,
                amountB * totalSupply() / reserveB
            );
        }
        
        //调用父合约（ERC20）的 _mint
        //把新发行的 LP 代币给提供者
        //totalSupply() 会增加
        _mint(msg.sender, liquidity);

        //在合约内部更新储备计数器
        reserveA += amountA;
        reserveB += amountB;

        //发出事件，记录这次操作
        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    //removeLiquidity 函数（移除流动性）
    function removeLiquidity(uint256 liquidityToRemove) external returns (uint256 amountAOut, uint256 amountBOut) {
        //检查输入参数，确保数量大于 0
        //检查提供者是否有足够的 LP 代币
        require(liquidityToRemove > 0, "Liquidity to remove must be > 0");
        require(balanceOf(msg.sender) >= liquidityToRemove, "Insufficient liquidity tokens");

        //获取当前池中 LP 代币总量，不能为 0
        uint256 totalLiquidity = totalSupply();
        require(totalLiquidity > 0, "No liquidity in the pool");

        //按比例把储备分给 LP，线性按比例赎回公式
        amountAOut = liquidityToRemove * reserveA / totalLiquidity;
        amountBOut = liquidityToRemove * reserveB / totalLiquidity;

        //防止返回 0 的情况（否则 transfer 可能也会失效或是没意义）
        require(amountAOut > 0 && amountBOut > 0, "Insufficient reserves for requested liquidity");

        //内部储备计数减少
        reserveA -= amountAOut;
        reserveB -= amountBOut;

        //销毁调用者的 LP 代币（调用 _burn 会减少 totalSupply()，从而维护对应关系）
        _burn(msg.sender, liquidityToRemove);

        //将对应的代币转回给用户
        tokenA.transfer(msg.sender, amountAOut);
        tokenB.transfer(msg.sender, amountBOut);

        //返回实际取回的数额
        emit LiquidityRemoved(msg.sender, amountAOut, amountBOut, liquidityToRemove);
        return (amountAOut, amountBOut);
    }

    //swapAforB（用 A 换 B）
    function swapAforB(uint256 amountAIn, uint256 minBOut) external {
        //基本校验，不能 swap 为 0，且池里必须已有储备
        require(amountAIn > 0, "Amount must be > 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

        //对输入金额收取 0.3% 的手续费
        uint256 amountAInWithFee = amountAIn * 997 / 1000;
        //基于“常数乘积”模型 x * y = k 的简化输出公式
        uint256 amountBOut = reserveB * amountAInWithFee / (reserveA + amountAInWithFee);
        
        //最低预期输出检查，防止交易者因价格滑点或 MEV 被打劫
        //调用者在发送交易前会把 minBOut 设成自己能接受的最小值
        //若市场波动过大则 revert
        require(amountBOut >= minBOut, "Slippage too high");

        //先从交易者把 完整的 amountAIn 转入合约
        //然后合约把 amountBOut 转给交易者
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        //更新 “带费后的入池量” 加到 reserveA，并减少 reserveB
        reserveA += amountAInWithFee;
        reserveB -= amountBOut;

        //发出事件记录 swap
        emit TokensSwapped(msg.sender, address(tokenA), amountAIn, address(tokenB), amountBOut);
    }

    //swapBforA（用 B 换 A）——对称逻辑
    //逻辑与 swapAforB 对称
    function swapBforA(uint256 amountBIn, uint256 minAOut) external {
        require(amountBIn > 0, "Amount must be > 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

        uint256 amountBInWithFee = amountBIn * 997 / 1000;
        uint256 amountAOut = reserveA * amountBInWithFee / (reserveB + amountBInWithFee);

        require(amountAOut >= minAOut, "Slippage too high");

        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);

        reserveB += amountBInWithFee;
        reserveA -= amountAOut;

        emit TokensSwapped(msg.sender, address(tokenB), amountBIn, address(tokenA), amountAOut);
    }
    
    //getReserves()：外部可查询当前合约记录的 reserveA / reserveB
    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }
    
    //min：简单的返回较小者辅助函数
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    //sqrt：实现了整数的平方根（Babylonian method — 牛顿迭代法的一种）
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}