// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title AutomatedMarketMaker
 * @dev This was from day 25, unchanged
 */
contract AmmLp is Ownable, ERC20 {
    uint256 public immutable swapFee;
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public amountA;
    uint256 public amountB;

    constructor(
        string memory _name,
        string memory _symbol,
        IERC20 _tokenA,
        IERC20 _tokenB,
        uint256 _swapFee
    ) Ownable(msg.sender) ERC20(_name, _symbol) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        swapFee = _swapFee;
    }

    function addLiq(uint256 _amountA, uint256 _amountB) public {
        require(amountA > 0 && amountB > 0, "amounts must be more than zero");
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint256 liquidityAdded;
        uint256 totalSupply = this.totalSupply();
        if (totalSupply == 0) {
            liquidityAdded = squareRoot(_amountA * _amountB);
        } else {
            liquidityAdded = min(
                _amountA * totalSupply / amountA,
                _amountB * totalSupply / amountB
            );
        }
        _mint(msg.sender, liquidityAdded);

        amountA += _amountA;
        amountB += _amountB;

    }

    function removeLiq(uint256 amount) public returns(uint256 amountRemovedA, uint256 amountRemovedB) {
        require(amount > 0, "amount must be more than zero");
        require(balanceOf(msg.sender) >= amount, "not enough LP tokens");
        uint256 totalSupply = totalSupply();
        require(totalSupply > 0, "not enough supply");

        amountRemovedA = amount * amountA / totalSupply;
        amountRemovedB = amount * amountB / totalSupply;
        require(amountRemovedA > 0 && amountRemovedB > 0, "token amounts to remove more than zero");

        amountA -= amountRemovedA;
        amountB -= amountRemovedB;

        _burn(msg.sender, amount);
        tokenA.transfer(msg.sender, amountRemovedA);
        tokenB.transfer(msg.sender, amountRemovedB);
    }

    function swap(uint256 _amountA, uint256 _amountB, bool _isSellingA) public {
        require(_amountA > 0 && _amountB > 0, "amounts must be more than zero");
        require(amountA > 0 && amountB > 0, "not enough liquidity");

        uint256 soldAmount;
        uint256 soldAmountWithFee;
        uint256 boughtAmount;
        IERC20 soldToken;
        IERC20 boughtToken;
        if (_isSellingA) {
            soldAmount = _amountA;
            soldAmountWithFee = _amountA * (10_000 - swapFee) / 10_000;
            boughtAmount = amountB * soldAmountWithFee / (amountA + soldAmountWithFee);
            soldToken = tokenA;
            boughtToken = tokenB;
            amountA += soldAmountWithFee;
            amountB -= boughtAmount;
        } else { // is selling B
            soldAmount = _amountB;
            soldAmountWithFee = _amountB * (10_000 - swapFee) / 10_000;
            boughtAmount = amountA * soldAmountWithFee / (amountB + soldAmountWithFee);
            soldToken = tokenB;
            boughtToken = tokenA;
            amountB += soldAmountWithFee;
            amountA -= boughtAmount;
        }

        soldToken.transferFrom(msg.sender, address(this), soldAmount);
        boughtToken.transfer(msg.sender, boughtAmount);
    }

    function min(uint256 a, uint256 b) public pure returns(uint256 r) {
        r = a < b ? a : b;
    }

    function squareRoot(uint256 n) public pure returns(uint256 r) {
        // babylonian
        if (n > 3) {
            r = n;
            uint256 x = n / 2 + 1;
            while (x < r) {
                r = x;
                x = (n / x + x) / 2;
            }
        } else if (n != 0) {
            r = 1;
        }
    }
}
