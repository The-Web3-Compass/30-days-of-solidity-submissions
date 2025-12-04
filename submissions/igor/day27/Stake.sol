// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//retran,erc20,safeCast
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

// Interface for fetching ERC-20 metadata (decimals)
interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

contract Stake is ReentrancyGuard{
    using SafeCast for uint256;
    IERC20 stakingToken;
    IERC20 rewardToken;

    uint256 rewardRatePerSecond;
    address owner;
    uint8 stakingTokenDecimals;

    struct StakerInfo{
        uint256 tokenAmount;
        uint256 rewardDebt;
        uint256 lastUpdate;
    }

    mapping(address => StakerInfo) public stakers;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RewardRefilled(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(address _stakingToken, address _rewardToken,uint256 _rewardRatePerSecond){
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRatePerSecond = _rewardRatePerSecond;
        owner = msg.sender;

        try IERC20Metadata(_stakingToken).decimals() returns (uint8 decimals){
            stakingTokenDecimals = decimals;
        } catch(bytes memory){
            stakingTokenDecimals = 18;
        }
    }

    function stake(uint256 _amount) public{
        require(_amount > 0,"");
        updateRewards(msg.sender);

        stakingToken.transferFrom(msg.sender,address(this),_amount);
        stakers[msg.sender].tokenAmount += _amount;
        emit Staked(msg.sender,_amount);
    }

    function unstake(uint256 _amount) public {
        require(_amount <= stakers[msg.sender].tokenAmount,"");
        updateRewards(msg.sender);

        stakingToken.transferFrom(address(this),msg.sender,_amount);
        stakers[msg.sender].tokenAmount -= _amount;
        emit Unstaked(msg.sender, _amount);
    }

    function claimRewards() public {
        require(stakers[msg.sender].tokenAmount > 0,"");
        updateRewards(msg.sender);
        uint256 pendingReward = stakers[msg.sender].rewardDebt;

        require(address(this).balance > pendingReward,"");
        stakers[msg.sender].rewardDebt = 0;
        rewardToken.transfer(msg.sender,pendingReward);

        emit RewardClaimed(msg.sender, pendingReward);
    }

    function emergencyWithdraw() public{
        uint256 amount = stakers[msg.sender].tokenAmount;
        stakers[msg.sender].tokenAmount = 0;
        stakers[msg.sender].rewardDebt = 0;
        stakers[msg.sender].lastUpdate = block.timestamp;

        stakingToken.transferFrom(address(this),msg.sender,amount);
        emit EmergencyWithdraw(msg.sender,amount);
    }

    function refillRewards(uint256 amount) external onlyOwner {
        rewardToken.transferFrom(msg.sender, address(this), amount);

        emit RewardRefilled(msg.sender, amount);
    }

    function pendingRewards(address user) external view returns (uint256) {
        StakerInfo memory staker = stakers[user];

        uint256 pendingReward = staker.rewardDebt;

        if (staker.tokenAmount > 0) {
            uint256 timeDiff = block.timestamp - staker.lastUpdate;
            uint256 rewardMultiplier = 10 ** stakingTokenDecimals;
            pendingReward += (timeDiff * rewardRatePerSecond * staker.tokenAmount) / rewardMultiplier;
        }

        return pendingReward;
    }

    function updateRewards(address _user) internal{
        StakerInfo storage staker = stakers[_user];

        if(staker.tokenAmount > 0){
            uint256 intervalo = block.timestamp - staker.lastUpdate;
            uint256 pendingReward = (intervalo * rewardRatePerSecond * staker.tokenAmount) / (10 ** stakingTokenDecimals);
            staker.rewardDebt += pendingReward;
        }
        staker.lastUpdate = block.timestamp;
    }

}