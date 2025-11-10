// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// custom err
error InsufficientLiquidity();
error InvalidToken();
error ZeroAddress();
error IdenticalTokens();
error InvalidAmount();
error InsufficientLPAmount();
error InsufficientOutputAmount();
error InsufficientInputAmount();
error InvalidRecipient();
error NotOwner();

// LP contract
contract MiniDexLPToken is ERC20 {
    address public immutable owner;

    constructor() ERC20("MiniDex LP Token", "MDLP") {
        // The creator of this contract (the MiniDexPair contract) becomes the owner.
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // Mints tokens to a specified address. Can only be called by the owner (the Pair contract).
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Burns tokens from its own balance. Can only be called by the owner (the Pair contract). The Pair contract must receive the tokens before it can burn them.*/
    function burn(uint256 amount) external onlyOwner {
        _burn(address(this), amount);
    }
}


// DEX Pair Contract                          
contract MiniDexPair is ReentrancyGuard {
    address public immutable tokenA;
    address public immutable tokenB;
    MiniDexLPToken public immutable lpToken;

    uint256 public reserveA;
    uint256 public reserveB;

    // A 0.3% fee is applied to all swaps.
    uint256 private constant FEE_NUMERATOR = 997;
    uint256 private constant FEE_DENOMINATOR = 1000;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpTokensMinted);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpTokensBurned);
    event Swapped(address indexed user, address indexed inputToken, uint256 inputAmount, address indexed outputToken, uint256 outputAmount);

    constructor(address _tokenA, address _tokenB) {
        if (_tokenA == _tokenB) revert IdenticalTokens();
        if (_tokenA == address(0) || _tokenB == address(0)) revert ZeroAddress();

        tokenA = _tokenA;
        tokenB = _tokenB;
        
        // Create the associated LP token contract. This contract (MiniDexPair)
        // becomes the owner of the lpToken, giving it minting/burning rights.
        lpToken = new MiniDexLPToken();
    }

    // INTERNAL UTILITIES

    function _updateReserves(uint256 _reserveA, uint256 _reserveB) private {
        reserveA = _reserveA;
        reserveB = _reserveB;
    }

    function _sqrt(uint y) private pure returns (uint z) {
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

    // CORE LOGIC

    function addLiquidity(uint256 amountADesired, uint256 amountBDesired) external nonReentrant returns (uint256 amountA, uint256 amountB, uint256 lpTokens) {
        if (amountADesired == 0 || amountBDesired == 0) revert InvalidAmount();

        if (reserveA == 0 && reserveB == 0) {
            // This is the first liquidity provision.
            amountA = amountADesired;
            amountB = amountBDesired;
        } else {
            // Calculate the optimal amount of token B for the desired amount of token A, or vice-versa.
            uint amountBOptimal = (amountADesired * reserveB) / reserveA;
            if (amountBOptimal <= amountBDesired) {
                amountA = amountADesired;
                amountB = amountBOptimal;
            } else {
                uint amountAOptimal = (amountBDesired * reserveA) / reserveB;
                amountA = amountAOptimal;
                amountB = amountBDesired;
            }
        }

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        uint256 totalSupply = lpToken.totalSupply();
        if (totalSupply == 0) {
            lpTokens = _sqrt(amountA * amountB);
        } else {
            lpTokens = (amountA * totalSupply) / reserveA;
        }
        if (lpTokens == 0) revert InsufficientLiquidity();

        // The pair contract calls the mint function on its own LP token contract.
        lpToken.mint(msg.sender, lpTokens);
        _updateReserves(IERC20(tokenA).balanceOf(address(this)), IERC20(tokenB).balanceOf(address(this)));

        emit LiquidityAdded(msg.sender, amountA, amountB, lpTokens);
    }

    function removeLiquidity(uint256 lpAmount) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        if (lpAmount == 0 || lpAmount > lpToken.balanceOf(msg.sender)) revert InsufficientLPAmount();

        uint256 totalSupply = lpToken.totalSupply();
        amountA = (lpAmount * reserveA) / totalSupply;
        amountB = (lpAmount * reserveB) / totalSupply;

        if (amountA == 0 || amountB == 0) revert InsufficientLiquidity();

        // User transfers LP tokens to the pair, then the pair burns them.
        lpToken.transferFrom(msg.sender, address(this), lpAmount);
        lpToken.burn(lpAmount);

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        _updateReserves(IERC20(tokenA).balanceOf(address(this)), IERC20(tokenB).balanceOf(address(this)));

        emit LiquidityRemoved(msg.sender, amountA, amountB, lpAmount);
    }

    function swap(uint256 inputAmount, address inputToken, address recipient) external nonReentrant {
        if (inputAmount == 0) revert InsufficientInputAmount();
        if (inputToken != tokenA && inputToken != tokenB) revert InvalidToken();
        if (recipient == address(0)) revert InvalidRecipient();

        uint256 outputAmount = getAmountOut(inputAmount, inputToken);
        if (outputAmount == 0) revert InsufficientOutputAmount();

        (uint256 inputReserve,) = inputToken == tokenA ? (reserveA, reserveB) : (reserveB, reserveA);
        address outputToken = inputToken == tokenA ? tokenB : tokenA;

        IERC20(inputToken).transferFrom(msg.sender, address(this), inputAmount);
        IERC20(outputToken).transfer(recipient, outputAmount);

        _updateReserves(IERC20(tokenA).balanceOf(address(this)), IERC20(tokenB).balanceOf(address(this)));

        emit Swapped(msg.sender, inputToken, inputAmount, outputToken, outputAmount);
    }

    // VIEW FUNCTIONS

    function getAmountOut(uint256 inputAmount, address inputToken) public view returns (uint256) {
        if (inputToken != tokenA && inputToken != tokenB) revert InvalidToken();
        if (inputAmount == 0) revert InsufficientInputAmount();
        if (reserveA == 0 || reserveB == 0) revert InsufficientLiquidity();

        (uint256 inputReserve, uint256 outputReserve) = inputToken == tokenA ? (reserveA, reserveB) : (reserveB, reserveA);

        uint256 inputWithFee = inputAmount * FEE_NUMERATOR;
        uint256 numerator = inputWithFee * outputReserve;
        uint256 denominator = (inputReserve * FEE_DENOMINATOR) + inputWithFee;

        return numerator / denominator;
    }

    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }
}