//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//从 OpenZeppelin 库中导入 ERC20 接口标准
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//引入防止可重入攻击的安全模块
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//定义一个名为 MiniDexPair 的合约，并继承 ReentrancyGuard
//创建一个迷你去中心化交易所 
contract MiniDexPair is ReentrancyGuard {
    //定义两个不可变的公共地址变量，用于存储代币 A 和代币 B 的地址
    address public immutable tokenA;
    address public immutable tokenB;

    //储备池中 tokenA 、tokenB 的数量
    uint256 public reserveA;
    uint256 public reserveB;

    //所有 LP 代币的总供应量
    //用于计算每个流动性提供者的占比
    uint256 public totalLPSupply;

    //储存每个地址的 LP 余额
    mapping(address => uint256) public lpBalances;

    //当用户添加流动性时触发的事件
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpMinted);
    //记录用户移除流动性
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpBurned);
    //记录一次代币交换的详情
    event Swapped(address indexed user, address inputToken, uint256 inputAmount, address outputToken, uint256 outputAmount);

    //初始化函数，在部署时执行一次
    //设置交易对中两种代币
    constructor(address _tokenA, address _tokenB) {
        //检查两种代币是否不同
        require(_tokenA != _tokenB, "Identical tokens");
        //检查地址是否为零地址
        require(_tokenA != address(0) && _tokenB != address(0), "Zero address");

        //将传入的代币地址赋值给合约状态变量
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    //计算平方根的内部函数
    function sqrt(uint y) internal pure returns (uint z) {
        //当输入值大于 3 时执行迭代计算
        if (y > 3) {
            //初始化估算值
            z = y;
            uint x = y / 2 + 1;
            //执行迭代，直到误差最小
            //牛顿迭代法计算平方根
            while (x < z) {
                //更新估算值
                //逐步逼近平方根
                z = x;
                x = (y / x + x) / 2;
            }
        //当 y 不为 0 但小于 4 时返回 1
        } else if (y != 0) {
            z = 1;
        }
    }

    //声明一个内部纯函数 min，返回两个数字中的较小值
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        //使用三元运算符判断并返回较小值
        //快速返回 a 与 b 中的最小数
        return a < b ? a : b;
    }

    //定义一个私有函数 _updateReserves
    //重新同步合约中持有的代币余额到 reserveA 和 reserveB
    function _updateReserves() private {
        //查询当前合约中持有的 tokenA 数量并赋值给 reserveA
        reserveA = IERC20(tokenA).balanceOf(address(this));
        //同上
        reserveB = IERC20(tokenB).balanceOf(address(this));
    }

    //定义一个外部函数，用于用户添加流动性
    //用户将两种代币存入池中，换取 LP 代币份额
    function addLiquidity(uint256 amountA, uint256 amountB) external nonReentrant {
        //验证输入的代币数量是否都大于零
        require(amountA > 0 && amountB > 0, "Invalid amounts");

        //从用户地址转移 amountA 个 tokenA 到本合约
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        //同上
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        //定义局部变量 lpToMint
        //存储本次要发行的 LP 代币数量
        uint256 lpToMint;
        //判断当前池子是否首次添加流动性
        if (totalLPSupply == 0) {
            //如果是第一次添加，则 LP 数量为 √(A×B)
            lpToMint = sqrt(amountA * amountB);
        } else {     //否则
            //计算用户可以获得的 LP 代币数量
            //根据用户提供的代币数量与当前储备量的比例计算
            //取两种代币计算出的 LP 数量的较小值
            lpToMint = min(
                (amountA * totalLPSupply) / reserveA,
                (amountB * totalLPSupply) / reserveB
            );
        }

        //检查是否成功计算出正数 LP 数量
        require(lpToMint > 0, "Zero LP minted");

        //增加当前用户的 LP 余额
        lpBalances[msg.sender] += lpToMint;
        //更新整个池子的 LP 总供应量
        totalLPSupply += lpToMint;

        //调用内部函数，重新同步储备量
        _updateReserves();

        //触发事件，记录本次添加流动性的详细数据
        emit LiquidityAdded(msg.sender, amountA, amountB, lpToMint);
    }

    //定义一个函数供用户提取流动性
    //用户销毁一定数量 LP 代币，取回对应比例的 tokenA 和 tokenB
    function removeLiquidity(uint256 lpAmount) external nonReentrant {
        //检查 LP 提取数量是否有效且不超过用户持有量
        require(lpAmount > 0 && lpAmount <= lpBalances[msg.sender], "Invalid LP amount");

        //根据 LP 占比计算用户应得的 tokenA 数量
        uint256 amountA = (lpAmount * reserveA) / totalLPSupply;
        //同上
        uint256 amountB = (lpAmount * reserveB) / totalLPSupply;

        //减少用户的 LP 持有量
        lpBalances[msg.sender] -= lpAmount;
        //减少系统中 LP 总供应量
        totalLPSupply -= lpAmount;

        //将计算出的 tokenA 数量返还给用户
        IERC20(tokenA).transfer(msg.sender, amountA);
        //同上
        IERC20(tokenB).transfer(msg.sender, amountB);

        //更新池中剩余储备量
        _updateReserves();

        //触发事件，记录用户提取流动性的详情
        emit LiquidityRemoved(msg.sender, amountA, amountB, lpAmount);
    }

    //定义一个公开的只读函数，用于计算交易输出量
    //根据恒定乘积公式（x * y = k）计算兑换比例
    function getAmountOut(uint256 inputAmount, address inputToken) public view returns (uint256 outputAmount) {
        //确认输入代币必须是交易对之一
        require(inputToken == tokenA || inputToken == tokenB, "Invalid input token");

        //判断输入是否为 tokenA
        bool isTokenA = inputToken == tokenA;
        //根据输入代币类型确定储备池对应关系
        //若输入是 tokenA，则输出池为 tokenB，反之亦然
        (uint256 inputReserve, uint256 outputReserve) = isTokenA ? (reserveA, reserveB) : (reserveB, reserveA);

        //对输入金额应用 0.3% 交易手续费
        //模拟 Uniswap 手续费机制 (1000 - 997 = 3)
        uint256 inputWithFee = inputAmount * 997;

        //按恒定乘积公式计算输出量分子分母
        //实现公式：Δy = (Δx * y * 997) / (x * 1000 + Δx * 997)
        uint256 numerator = inputWithFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + inputWithFee;

        //计算最终可获得的输出代币数量
        outputAmount = numerator / denominator;
    }

    //定义主交易函数
    //用户输入一种代币，从池中换出另一种代币
    function swap(uint256 inputAmount, address inputToken) external nonReentrant {
        //检查输入数量大于零
        require(inputAmount > 0, "Zero input");
        //检查输入代币是否合法，只允许交易对中的代币
        require(inputToken == tokenA || inputToken == tokenB, "Invalid token");

        //确定交易输出的代币种类
        address outputToken = inputToken == tokenA ? tokenB : tokenA;
        //调用上面函数计算可获得的输出代币量
        uint256 outputAmount = getAmountOut(inputAmount, inputToken);

        //确保输出代币数量合理
        require(outputAmount > 0, "Insufficient output");

        //从用户地址接收输入代币
        IERC20(inputToken).transferFrom(msg.sender, address(this), inputAmount);
        //向用户发送输出代币
        IERC20(outputToken).transfer(msg.sender, outputAmount);

        //向用户发送输出代币
        _updateReserves();

        //触发事件，记录本次交换详细信息
        emit Swapped(msg.sender, inputToken, inputAmount, outputToken, outputAmount);
    }

    //公开函数，返回储备池中的两种代币数量
    function getReserves() external view returns (uint256, uint256) {
        //返回储备量
        return (reserveA, reserveB);
    }

    //查询指定用户的 LP 余额
    function getLPBalance(address user) external view returns (uint256) {
        //返回对应地址的 LP 数量
        return lpBalances[user];
    }

    //查询 LP 总供应量
    function getTotalLPSupply() external view returns (uint256) {
        //返回总发行 LP 数
        return totalLPSupply;
    }
}