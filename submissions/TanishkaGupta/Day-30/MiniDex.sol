// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MiniDex {

    uint256 public reserveETH;
    uint256 public reserveToken;

    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;

    event LiquidityAdded(address indexed user, uint256 ethAmount, uint256 tokenAmount);
    event LiquidityRemoved(address indexed user, uint256 ethAmount, uint256 tokenAmount);
    event Swapped(address indexed user, uint256 inputAmount, uint256 outputAmount);

    /*
     * Add Liquidity
     */
    function addLiquidity(uint256 tokenAmount) external payable {

        if (totalLiquidity == 0) {
            reserveETH = msg.value;
            reserveToken = tokenAmount;
            totalLiquidity = msg.value;
            liquidity[msg.sender] = totalLiquidity;
        } else {
            uint256 requiredToken = (msg.value * reserveToken) / reserveETH;
            require(tokenAmount >= requiredToken, "Invalid ratio");

            uint256 liquidityMinted = (msg.value * totalLiquidity) / reserveETH;

            reserveETH += msg.value;
            reserveToken += requiredToken;

            liquidity[msg.sender] += liquidityMinted;
            totalLiquidity += liquidityMinted;
        }

        emit LiquidityAdded(msg.sender, msg.value, tokenAmount);
    }

    /*
     * Remove Liquidity
     */
    function removeLiquidity(uint256 amount) external {

        require(liquidity[msg.sender] >= amount, "Not enough liquidity");

        uint256 ethAmount = (amount * reserveETH) / totalLiquidity;
        uint256 tokenAmount = (amount * reserveToken) / totalLiquidity;

        liquidity[msg.sender] -= amount;
        totalLiquidity -= amount;

        reserveETH -= ethAmount;
        reserveToken -= tokenAmount;

        payable(msg.sender).transfer(ethAmount);
        // Token transfer skipped (for simplicity)

        emit LiquidityRemoved(msg.sender, ethAmount, tokenAmount);
    }

    /*
     * Swap ETH → Token
     */
    function swapETHForTokens() external payable {

        require(msg.value > 0, "Send ETH");

        uint256 output = getAmountOut(msg.value, reserveETH, reserveToken);

        reserveETH += msg.value;
        reserveToken -= output;

        // Token transfer skipped

        emit Swapped(msg.sender, msg.value, output);
    }

    /*
     * Swap Token → ETH
     */
    function swapTokensForETH(uint256 tokenAmount) external {

        require(tokenAmount > 0, "Invalid amount");

        uint256 output = getAmountOut(tokenAmount, reserveToken, reserveETH);

        reserveToken += tokenAmount;
        reserveETH -= output;

        payable(msg.sender).transfer(output);

        emit Swapped(msg.sender, tokenAmount, output);
    }

    /*
     * AMM Formula (x * y = k)
     */
    function getAmountOut(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {

        uint256 inputWithFee = inputAmount * 997;
        uint256 numerator = inputWithFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + inputWithFee;

        return numerator / denominator;
    }
}