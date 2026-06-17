// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IERC20Minimal.sol";

contract AMMPair {
    // tokens
    IERC20Minimal public token0;
    IERC20Minimal public token1;

    // reserves (fits in uint112 like Uniswap)
    uint112 private reserve0;
    uint112 private reserve1;

    // LP token (minimal ERC20)
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply; // LP total supply
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // constants
    uint256 public constant MINIMUM_LIQUIDITY = 1000;
    uint256 public feeNumerator = 997; // 0.3% fee
    uint256 public feeDenominator = 1000;

    // events
    event Mint(address indexed sender, uint amount0, uint amount1, uint liquidity);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    event Transfer(address indexed from, address indexed to, uint value); // LP token transfer
    event Approval(address indexed owner, address indexed spender, uint value); // LP token approval

    constructor(address _token0, address _token1) {
        require(_token0 != _token1, "AMMPair: IDENTICAL_ADDRESSES");
        token0 = IERC20Minimal(_token0);
        token1 = IERC20Minimal(_token1);
        name = string(abi.encodePacked("LP-", tokenSymbol(_token0), "/", tokenSymbol(_token1)));
        symbol = "AMM-LP";
    }

    // --- Minimal LP ERC20 functions ---
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transferLP(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "AMMPair: LP allowance too low");
        allowance[from][msg.sender] = allowed - amount;
        _transferLP(from, to, amount);
        return true;
    }

    function _transferLP(address from, address to, uint256 value) internal {
        require(balanceOf[from] >= value, "AMMPair: LP transfer exceeds balance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    // --- View reserves ---
    function getReserves() public view returns (uint112, uint112) {
        return (reserve0, reserve1);
    }

    // update reserves
    function _update(uint256 balance0, uint256 balance1) internal {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "AMMPair: overflow");
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        emit Sync(reserve0, reserve1);
    }

    // Add liquidity (user must approve this pair to spend tokens)
    function addLiquidity(uint256 amount0, uint256 amount1) external returns (uint256 liquidity) {
        require(amount0 > 0 && amount1 > 0, "AMMPair: INSUFFICIENT_AMOUNT");
        // transfer tokens in
        require(token0.transferFrom(msg.sender, address(this), amount0), "AMMPair: TRANSFER_FAILED0");
        require(token1.transferFrom(msg.sender, address(this), amount1), "AMMPair: TRANSFER_FAILED1");

        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));

        uint256 _totalSupply = totalSupply;

        if (_totalSupply == 0) {
            // initial liquidity
            liquidity = sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            // lock MINIMUM_LIQUIDITY to address(0)
            totalSupply = MINIMUM_LIQUIDITY;
            balanceOf[address(0)] = MINIMUM_LIQUIDITY;
            // mint liquidity to provider
            totalSupply += liquidity;
            balanceOf[msg.sender] += liquidity;
        } else {
            uint256 liquidity0 = (amount0 * _totalSupply) / reserve0;
            uint256 liquidity1 = (amount1 * _totalSupply) / reserve1;
            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
            require(liquidity > 0, "AMMPair: INSUFFICIENT_LIQUIDITY_MINTED");
            totalSupply += liquidity;
            balanceOf[msg.sender] += liquidity;
        }

        _update(balance0, balance1);
        emit Mint(msg.sender, amount0, amount1, liquidity);
    }

    // Remove liquidity (burn LP and send underlying tokens)
    function removeLiquidity(uint256 liquidity) external returns (uint256 amount0, uint256 amount1) {
        require(liquidity > 0, "AMMPair: ZERO_LIQUIDITY");
        require(balanceOf[msg.sender] >= liquidity, "AMMPair: INSUFFICIENT_LP");
        uint256 _totalSupply = totalSupply;
        amount0 = (liquidity * reserve0) / _totalSupply;
        amount1 = (liquidity * reserve1) / _totalSupply;
        require(amount0 > 0 && amount1 > 0, "AMMPair: INSUFFICIENT_AMOUNT");

        // burn
        balanceOf[msg.sender] -= liquidity;
        totalSupply -= liquidity;
        emit Transfer(msg.sender, address(0), liquidity);

        require(token0.transfer(msg.sender, amount0), "AMMPair: TRANSFER_FAILED0");
        require(token1.transfer(msg.sender, amount1), "AMMPair: TRANSFER_FAILED1");

        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        _update(balance0, balance1);
        emit Burn(msg.sender, amount0, amount1, msg.sender);
    }

    // Swap: caller must have transferred token in prior to calling swap OR transfer in and then call swap.
    // To keep API simple: user calls swap specifying desired amountOut for one side; they must transfer input token first.
    // Only one of amount0Out / amount1Out can be non-zero.
    function swap(uint256 amount0Out, uint256 amount1Out, address to) external {
        require((amount0Out == 0) != (amount1Out == 0), "AMMPair: ONLY_ONE_SIDE_OUT");
        require(amount0Out < reserve0 && amount1Out < reserve1, "AMMPair: INSUFFICIENT_LIQUIDITY");

        uint256 balance0Before = token0.balanceOf(address(this));
        uint256 balance1Before = token1.balanceOf(address(this));

        // send out
        if (amount0Out > 0) {
            require(token0.transfer(to, amount0Out), "AMMPair: TRANSFER_OUT0_FAILED");
        }
        if (amount1Out > 0) {
            require(token1.transfer(to, amount1Out), "AMMPair: TRANSFER_OUT1_FAILED");
        }

        uint256 balance0After = token0.balanceOf(address(this));
        uint256 balance1After = token1.balanceOf(address(this));

        // compute amounts in
        uint256 amount0In = 0;
        uint256 amount1In = 0;

        if (balance0After > balance0Before - amount0Out) {
            amount0In = balance0After - (balance0Before - amount0Out);
        }
        if (balance1After > balance1Before - amount1Out) {
            amount1In = balance1After - (balance1Before - amount1Out);
        }

        require(amount0In > 0 || amount1In > 0, "AMMPair: INSUFFICIENT_INPUT_AMOUNT");

        // enforce constant product invariant with fee
        uint256 adjusted0 = (balance0After * feeNumerator) / feeDenominator;
        uint256 adjusted1 = (balance1After * feeNumerator) / feeDenominator;

        // require adjusted0 * adjusted1 >= reserve0 * reserve1
        require(adjusted0 * adjusted1 >= uint256(reserve0) * uint256(reserve1), "AMMPair: K");

        _update(balance0After, balance1After);

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // helper sqrt
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

    // helper to read a token symbol via interface call (non-reverting path)
    function tokenSymbol(address token) internal view returns (string memory) {
        try IERC20Minimal(token).symbol() returns (string memory s) {
            return s;
        } catch {
            return "";
        }
    }
}
