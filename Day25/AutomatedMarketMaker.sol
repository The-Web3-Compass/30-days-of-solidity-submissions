// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract AutomatedMarketMaker {
    string public name = "Simple AMM LP Token";
    string public symbol = "sAMM-LP";
    uint8 public decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    interface IERC20 {
        function totalSupply() external view returns (uint256);
        function balanceOf(address owner) external view returns (uint256);
        function transfer(address to, uint256 amount) external returns (bool);
        function transferFrom(address from, address to, uint256 amount) external returns (bool);
        function approve(address spender, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
    }

    IERC20 public token0;
    IERC20 public token1;

    uint256 private reserve0;
    uint256 private reserve1;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1, uint256 liquidity);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, uint256 liquidity);
    event Swap(address indexed sender, uint256 amountIn, uint256 amountOut, address indexed tokenIn, address indexed tokenOut);
    event Sync(uint256 reserve0, uint256 reserve1);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 private constant MINIMUM_LIQUIDITY = 10**3;
    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "AMM: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address _token0, address _token1) {
        require(_token0 != _token1, "AMM: IDENTICAL_ADDRESSES");
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function _mintLP(address to, uint256 value) internal {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burnLP(address from, uint256 value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transferLP(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= value, "AMM: ALLOWANCE_EXCEEDED");
        allowance[from][msg.sender] = allowed - value;
        _transferLP(from, to, value);
        return true;
    }

    function _transferLP(address from, address to, uint256 value) internal {
        require(balanceOf[from] >= value, "AMM: INSUFFICIENT_BALANCE");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function addLiquidity(uint256 amount0Desired, uint256 amount1Desired) external lock returns (uint256 liquidity) {
        require(amount0Desired > 0 && amount1Desired > 0, "AMM: ZERO_AMOUNT");
        require(token0.transferFrom(msg.sender, address(this), amount0Desired), "AMM: TRANSFER_FAILED0");
        require(token1.transferFrom(msg.sender, address(this), amount1Desired), "AMM: TRANSFER_FAILED1");
        uint256 _reserve0 = reserve0;
        uint256 _reserve1 = reserve1;
        if (totalSupply == 0) {
            uint256 amount = _sqrt(amount0Desired * amount1Desired);
            require(amount > MINIMUM_LIQUIDITY, "AMM: INSUFFICIENT_LIQUIDITY");
            liquidity = amount - MINIMUM_LIQUIDITY;
            _mintLP(address(0), MINIMUM_LIQUIDITY);
            _mintLP(msg.sender, liquidity);
        } else {
            uint256 liquidity0 = (amount0Desired * totalSupply) / _reserve0;
            uint256 liquidity1 = (amount1Desired * totalSupply) / _reserve1;
            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
            require(liquidity > 0, "AMM: INSUFFICIENT_LIQUIDITY_MINTED");
            _mintLP(msg.sender, liquidity);
        }
        _updateReserves(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
        emit Mint(msg.sender, amount0Desired, amount1Desired, liquidity);
    }

    function removeLiquidity(uint256 liquidity) external lock returns (uint256 amount0, uint256 amount1) {
        require(liquidity > 0, "AMM: ZERO_LIQUIDITY");
        require(balanceOf[msg.sender] >= liquidity, "AMM: NOT_ENOUGH_LP");
        uint256 _totalSupply = totalSupply;
        uint256 _reserve0 = reserve0;
        uint256 _reserve1 = reserve1;
        amount0 = (liquidity * _reserve0) / _totalSupply;
        amount1 = (liquidity * _reserve1) / _totalSupply;
        require(amount0 > 0 && amount1 > 0, "AMM: INSUFFICIENT_LIQUIDITY_BURNED");
        _burnLP(msg.sender, liquidity);
        require(token0.transfer(msg.sender, amount0), "AMM: TRANSFER_FAILED0");
        require(token1.transfer(msg.sender, amount1), "AMM: TRANSFER_FAILED1");
        _updateReserves(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
        emit Burn(msg.sender, amount0, amount1, liquidity);
    }

    function swapExactTokensForTokens(address tokenIn, uint256 amountIn, uint256 minAmountOut) external lock returns (uint256 amountOut) {
        require(amountIn > 0, "AMM: ZERO_AMOUNT_IN");
        require(tokenIn == address(token0) || tokenIn == address(token1), "AMM: INVALID_TOKEN");
        bool isToken0 = tokenIn == address(token0);
        IERC20 inToken = isToken0 ? token0 : token1;
        IERC20 outToken = isToken0 ? token1 : token0;
        require(inToken.transferFrom(msg.sender, address(this), amountIn), "AMM: TRANSFER_IN_FAILED");
        uint256 _reserveIn = isToken0 ? reserve0 : reserve1;
        uint256 _reserveOut = isToken0 ? reserve1 : reserve0;
        require(_reserveIn > 0 && _reserveOut > 0, "AMM: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = (amountIn * 997) / 1000;
        uint256 numerator = amountInWithFee * _reserveOut;
        uint256 denominator = _reserveIn + amountInWithFee;
        amountOut = numerator / denominator;
        require(amountOut >= minAmountOut, "AMM: SLIPPAGE_EXCEEDED");
        require(amountOut > 0, "AMM: INSUFFICIENT_OUTPUT_AMOUNT");
        require(outToken.transfer(msg.sender, amountOut), "AMM: TRANSFER_OUT_FAILED");
        _updateReserves(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
        emit Swap(msg.sender, amountIn, amountOut, tokenIn, address(outToken));
    }

    function _updateReserves(uint256 balance0, uint256 balance1) internal {
        reserve0 = balance0;
        reserve1 = balance1;
        emit Sync(reserve0, reserve1);
    }

    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y == 0) return 0;
        uint256 x = y;
        z = 1;
        if (x >= 0x100000000000000000000000000000000) { x >>= 128; z <<= 64; }
        if (x >= 0x10000000000) { x >>= 64; z <<= 32; }
        if (x >= 0x1000000) { x >>= 32; z <<= 16; }
        if (x >= 0x10000) { x >>= 16; z <<= 8; }
        if (x >= 0x100) { x >>= 8; z <<= 4; }
        if (x >= 0x10) { x >>= 4; z <<= 2; }
        if (x >= 0x4) { x >>= 2; z <<= 1; }
        for (uint i = 0; i < 64; i++) {
            uint256 zOld = z;
            z = (z + y / z) >> 1;
            if (z == zOld) break;
        }
    }
}
