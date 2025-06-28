// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract SimpleDEX {
    address public token1;
    address public token2;

    mapping(address => uint256) public liquidityProvided;
    uint256 public totalLiquidity;

    constructor(address _token1, address _token2) {
        token1 = _token1;
        token2 = _token2;
    }

    function addLiquidity(uint256 amount1, uint256 amount2) external {
        require(IERC20(token1).transferFrom(msg.sender, address(this), amount1), "Transfer failed");
        require(IERC20(token2).transferFrom(msg.sender, address(this), amount2), "Transfer failed");

        uint256 liquidity = amount1 + amount2; // Simplified
        liquidityProvided[msg.sender] += liquidity;
        totalLiquidity += liquidity;
    }

    function removeLiquidity(uint256 liquidity) external {
        require(liquidityProvided[msg.sender] >= liquidity, "Not enough liquidity");

        uint256 amount1 = (IERC20(token1).balanceOf(address(this)) * liquidity) / totalLiquidity;
        uint256 amount2 = (IERC20(token2).balanceOf(address(this)) * liquidity) / totalLiquidity;

        liquidityProvided[msg.sender] -= liquidity;
        totalLiquidity -= liquidity;

        require(IERC20(token1).transfer(msg.sender, amount1), "Transfer failed");
        require(IERC20(token2).transfer(msg.sender, amount2), "Transfer failed");
    }

    function swap(address fromToken, uint256 amountIn) external {
        address toToken = fromToken == token1 ? token2 : token1;

        require(IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn), "Transfer failed");

        uint256 reserveFrom = IERC20(fromToken).balanceOf(address(this));
        uint256 reserveTo = IERC20(toToken).balanceOf(address(this));

        uint256 amountOut = getSwapAmount(amountIn, reserveFrom - amountIn, reserveTo);

        require(IERC20(toToken).transfer(msg.sender, amountOut), "Swap failed");
    }

    function getSwapAmount(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        // Constant product formula with 0.3% fee
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        return numerator / denominator;
    }
}
