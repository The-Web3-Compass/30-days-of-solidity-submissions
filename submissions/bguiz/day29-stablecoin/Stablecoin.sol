// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Stablecoin
 * @dev Build a digital currency that maintains a stable value.
 * You'll learn how to keep the price steady using peg mechanisms, demonstrating stablecoin mechanics.
 * It's like a digital dollar, showing how to create stablecoins.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 29
 */
contract Stablecoin is Ownable, ReentrancyGuard, ERC20 {
    using SafeCast for uint256;
    
    AggregatorV3Interface public priceFeed;
    IERC20Metadata public collateralToken;
    uint8 public immutable collateralTokenDecimals;
    uint256 collateralizationRatio = 120_00;

    constructor(
        AggregatorV3Interface _priceFeed,
        IERC20Metadata _collateralToken
    )
        Ownable(msg.sender)
        ReentrancyGuard()
        ERC20("BG Dollar", "BGD")
    {
        require(address(_priceFeed) != address(0x00), "price feed canot be null address");
        require(address(_collateralToken) != address(0x00), "price feed canot be null address");
        priceFeed = _priceFeed;
        collateralToken = _collateralToken;
        collateralTokenDecimals = collateralToken.decimals();
    }

    function mint(uint256 amount) public nonReentrant {
        require(amount > 0, "amount msut be more than zero");
        uint256 collateralTokenPrice = getCollateralTokenPrice();
        uint256 collateralTokenAmount = (
            (amount * (10 ** decimals())) /
            (collateralTokenPrice * (10 ** collateralTokenDecimals) * collateralizationRatio / 100_00)
        );
        collateralToken.transferFrom(msg.sender, address(this), collateralTokenAmount);
        _mint(msg.sender, amount);
    }
    
    function burn(uint256 amount) public nonReentrant {
        require(amount > 0 && amount <= balanceOf(msg.sender), "invalid amount");
        uint256 collateralTokenPrice = getCollateralTokenPrice();
        uint256 collateralTokenAmount = (
            (amount * (10 ** decimals())) /
            (collateralTokenPrice * (10 ** collateralTokenDecimals) * collateralizationRatio / 100_00)
        );
        collateralToken.transfer(msg.sender, collateralTokenAmount);
        _burn(msg.sender, amount);
    }

    function getCollateralTokenPrice() public view returns(uint256 price) {
        (, int256 rawPrice, , ,) = priceFeed.latestRoundData();
        require(rawPrice > 0, "invalid price from oracle");
        price = uint256(rawPrice);
    }
}
