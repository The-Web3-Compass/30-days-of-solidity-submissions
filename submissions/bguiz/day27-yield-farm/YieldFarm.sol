// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// because decimals() is a common, but non-standard part of the ERC20 standard
interface IERC20WithInfo is IERC20 {
    function decimals() external view returns (uint8);
}

/**
 * @title YieldFarm
 * @dev Build a system for earning rewards by staking tokens.
 * You'll learn how to distribute rewards, demonstrating yield farming.
 * It's like a digital savings account with interest, showing how to create yield farming platforms.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 27
 */
contract YieldFarm is ReentrancyGuard, Ownable {
    using SafeCast for uint256;

    struct Stake {
        uint256 amount;
        uint256 reward;
        uint256 updatedTs;
    }

    IERC20 public stakeToken;
    IERC20 public rewardToken;
    uint256 public stakeTokenDecimals = 18;
    uint256 public rewardRate;
    mapping(address => Stake) public stakes;

    constructor(
        IERC20WithInfo _stakeToken,
        IERC20WithInfo _rewardToken,
        uint256 _rewardRate
    ) ReentrancyGuard() Ownable(msg.sender) {
        require(rewardRate > 0, "reward rate must be more than zero");
        require(
            address(_stakeToken) != address(0x00) &&
            address(_rewardToken) != address(0x00),
            "null adresses not allowed"
        );
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
        rewardRate = _rewardRate;
        try _stakeToken.decimals() returns (uint8 decimals) {
            stakeTokenDecimals = decimals;
        } catch {
            // do nothing, default is 18, and already set
        }
    }

    function updateStake(address staker) internal {
        Stake memory stake = stakes[staker];

        if (stake.amount > 0) {
            uint256 duration = block.timestamp - stake.updatedTs;
            uint256 e = 10 ** stakeTokenDecimals;
            stake.reward = duration * rewardRate * stake.amount / e;
            stake.updatedTs = block.timestamp;
        }

        stakes[staker] = stake;
    }

    function addStake(uint256 amount) public nonReentrant {
        require(amount > 0, "amount must be more than zero");
        stakeToken.transferFrom(msg.sender, address(this), amount);
        updateStake(msg.sender);
        stakes[msg.sender].amount += amount;
    }

    function removeStake(uint256 amount) public nonReentrant {
        require(amount > 0, "amount must be more than zero");
        require(stakes[msg.sender].amount >= amount, "amount more than staked");
        stakeToken.transfer(msg.sender, amount);
        updateStake(msg.sender);
        stakes[msg.sender].amount -= amount;
    }

    function withdrawRewards() public nonReentrant {
        updateStake(msg.sender);
        uint256 amount = stakes[msg.sender].reward;
        require(amount > 0, "reward is zero");
        require(rewardToken.balanceOf(address(this)) >= amount, "insufficient reward balance in farm");

        stakes[msg.sender].reward = 0;
        rewardToken.transfer(msg.sender, amount);
    }
}
