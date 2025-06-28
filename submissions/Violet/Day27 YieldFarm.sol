// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title MockERC20
 * @dev A simple ERC20 token for testing purposes.
 */
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply * (10**decimals()));
    }
}

/**
 * @title YieldFarm
 * @dev A simple yield farming contract where users can stake one token to earn another.
 */
contract YieldFarm is Ownable {
    using SafeMath for uint256;

    // --- State Variables ---
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    uint256 public rewardRate; // Rewards per second
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    // --- Events ---
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRate);

    constructor(
        address _stakingTokenAddress,
        address _rewardTokenAddress
    ) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingTokenAddress);
        rewardToken = IERC20(_rewardTokenAddress);
        lastUpdateTime = block.timestamp;
    }

    // --- Core Functions ---

    /**
     * @dev Stakes tokens into the farm.
     */
    function stake(uint256 amount) external {
        _updateReward(msg.sender);
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Unstakes tokens from the farm.
     */
    function unstake(uint256 amount) external {
        _updateReward(msg.sender);
        require(amount > 0, "Cannot unstake 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    /**
     * @dev Claims the accumulated rewards.
     */
    function claimReward() external {
        _updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
            emit RewardClaimed(msg.sender, reward);
        }
    }

    // --- Admin Functions ---

    /**
     * @dev Sets the reward rate.
     */
    function setRewardRate(uint256 rate) external onlyOwner {
        _updateRewardForAll();
        rewardRate = rate;
        emit RewardRateUpdated(rate);
    }
    
    /**
     * @dev Funds the contract with reward tokens.
     */
    function fund(uint256 amount) external onlyOwner {
        rewardToken.transferFrom(msg.sender, address(this), amount);
    }

    // --- View & Helper Functions ---

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(
            (lastTimeRewardApplicable().sub(lastUpdateTime) * rewardRate * 1e18) / _totalSupply
        );
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(
            rewardPerToken().sub(userRewardPerTokenPaid[account])
        ) / 1e18 + rewards[account];
    }
    
    function totalStaked() public view returns (uint256) {
        return _totalSupply;
    }

    function getStakedBalance(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _updateReward(address account) private {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }

    function _updateRewardForAll() private {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
    }
}
