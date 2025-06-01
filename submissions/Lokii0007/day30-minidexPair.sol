// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MiniDex is ReentrancyGuard {
    address public immutable tokenA;
    address public immutable tokenB;

    uint public reserveA;
    uint public reserveB;
    uint public totalLPSupply;

    mapping(address => uint) lpBalance;

    event LiquidityAdded(
        address indexed provider,
        uint amountA,
        uint amountB,
        uint lpMinted
    );
    event LiquidityRemoved(
        address indexed provider,
        uint amountA,
        uint amountB,
        uint lpBurned
    );
    event Swapped(
        address indexed user,
        address inputToken,
        uint inputAmount,
        address outputToken,
        uint outputAmount
    );

    constructor(address _tokenA, address _tokenB) {
        require(
            _tokenA != address(0) && _tokenB != address(0),
            "invalid token address"
        );
        require(_tokenA != _tokenB, "identical tokens");

        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function min(uint a, uint b) internal pure returns (uint) {
        return a > b ? b : a;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (z > x) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _updateReserves() private {
        reserveA = IERC20(tokenA).balanceOf(address(this));
        reserveB = IERC20(tokenB).balanceOf(address(this));
    }

    function addLiquidity(uint _amountA, uint _amountB) external nonReentrant {
        require(_amountB > 0 && _amountA > 0, "token amount cant be 0");

        IERC20(tokenA).transferFrom(msg.sender, address(this), _amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), _amountB);

        uint lpToMint = 0;

        if (totalLPSupply == 0) {
            lpToMint = sqrt(_amountB * _amountA);
        } else {
            lpToMint = min(
                (_amountA * totalLPSupply) / reserveA,
                (_amountB * totalLPSupply) / reserveB
            );
        }

        require(lpToMint > 0, "0 token to be minted");

        totalLPSupply += lpToMint;
        lpBalance[msg.sender] += lpToMint;
        _updateReserves();

        emit LiquidityAdded(msg.sender, _amountA, _amountB, lpToMint);
    }

    function removeLiquidity(uint _lpAmount) external nonReentrant {
        require(_lpAmount > 0 && lpBalance[msg.sender] >= _lpAmount , "invalid amount");

        uint amountA = (_lpAmount * reserveA)/ totalLPSupply;
        uint amountB = (_lpAmount * reserveB)/ totalLPSupply;

        lpBalance[msg.sender] -= _lpAmount;
        totalLPSupply -= _lpAmount;

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        _updateReserves();

        emit LiquidityRemoved(msg.sender, amountA, amountB, _lpAmount);
    }

    function getAmountOut(uint inputAmount, address inputToken) public view returns(uint ouputAmount){
        require(tokenB == inputToken || tokenA == inputToken, "invalid token");

        bool isTokenA = tokenA == inputToken;
        (uint inputReserve, uint outputReserve) = isTokenA ? (reserveA, reserveB) : (reserveB, reserveA);
        uint inputWithFee = inputAmount * 997;
        uint numerator = inputWithFee * outputReserve;
        uint denominator = (inputReserve * 1000) + inputReserve;
        ouputAmount = numerator/denominator;
    }

    function swap(uint inputAmount, address inputToken) external {
        require(inputAmount>0, "invalid amount");
        require(tokenB == inputToken || tokenA == inputToken, "invalid token");

        address outputToken = tokenA == inputToken ? tokenB : tokenA;
        uint outputAmount = getAmountOut(inputAmount, inputToken);
        
        require(outputAmount > 0, "output amount must be greater than 0");

        IERC20(inputToken).transferFrom(msg.sender, address(this), inputAmount);
        IERC20(outputToken).transfer(msg.sender, outputAmount);

        _updateReserves();

        emit Swapped(msg.sender, inputToken, inputAmount, outputToken, outputAmount);

    }

    function getReserves() external view returns(uint, uint){
        return (reserveA, reserveB);
    }

    function getLpBalance(address _user) external view returns(uint){
        return lpBalance[_user];
    }

    function getTotalLPSupply() external view returns(uint){
        return totalLPSupply;
    }
}
