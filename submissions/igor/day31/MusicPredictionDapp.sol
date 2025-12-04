// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MusicPredictionMarket {
    address public owner;
    IERC20 public stakingToken; // 用户押注的代币

    uint256 public nextSongId = 1;

    struct Song {
        uint256 id;
        string metadataURI; // 链下存储
    }

    enum PredictionType {
        SONG_PLAYS,  // 某首歌播放量
        TOP_SONG,    // 当日最高播放量歌曲
        TOP_N_RANK   // 某歌进入前 N
    }

    struct Prediction {
        address user;
        PredictionType pType;
        uint256 songId;
        uint256 targetValue; // 阈值/排名/播放量
        uint256 stakeAmount;
        bool claimed;
    }

    struct DailyResult {
        mapping(uint256 => uint256) songPlays; // songId -> 播放量
        uint256 topSongId;
        uint256 totalSongs;
        bool finalized;
    }

    
    mapping(uint256 => Song) public songs; // songId -> Song
    mapping(uint256 => Prediction[]) public dailyPredictions; // date -> Prediction[]
    mapping(uint256 => DailyResult) public dailyResults; // date -> DailyResult

    
    event SongAdded(uint256 songId, string metadataURI);
    event PredictionPlaced(uint256 date, address user, PredictionType pType, uint256 songId, uint256 targetValue, uint256 amount);
    event DailyResultSubmitted(uint256 date);
    event RewardClaimed(address user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(address _stakingToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
    }

    // ----------------------------
    // 歌曲管理
    // ----------------------------
    function addSong(string calldata metadataURI) external onlyOwner {
        songs[nextSongId] = Song(nextSongId, metadataURI);
        emit SongAdded(nextSongId, metadataURI);
        nextSongId++;
    }

    // ----------------------------
    // 用户下注
    // ----------------------------
    function placePrediction(
        uint256 date,
        PredictionType pType,
        uint256 songId,
        uint256 targetValue,
        uint256 stakeAmount
    ) external {
        require(stakingToken.transferFrom(msg.sender, address(this), stakeAmount), "transfer failed");

        dailyPredictions[date].push(Prediction({
            user: msg.sender,
            pType: pType,
            songId: songId,
            targetValue: targetValue,
            stakeAmount: stakeAmount,
            claimed: false
        }));

        emit PredictionPlaced(date, msg.sender, pType, songId, targetValue, stakeAmount);
    }

    
    function submitDailyResult(uint256 date, uint256[] calldata songIds, uint256[] calldata plays) external onlyOwner {
        require(!dailyResults[date].finalized, "already finalized");
        require(songIds.length == plays.length, "length mismatch");

        DailyResult storage result = dailyResults[date];
        uint256 topPlays = 0;
        uint256 topSongId = 0;

        for (uint256 i = 0; i < songIds.length; i++) {
            result.songPlays[songIds[i]] = plays[i];
            result.totalSongs++;
            if (plays[i] > topPlays) {
                topPlays = plays[i];
                topSongId = songIds[i];
            }
        }

        result.topSongId = topSongId;
        result.finalized = true;

        emit DailyResultSubmitted(date);
    }

    
    function claimReward(uint256 date, uint256 predictionIndex) external {
        DailyResult storage result = dailyResults[date];
        require(result.finalized, "result not finalized");

        Prediction storage pred = dailyPredictions[date][predictionIndex];
        require(pred.user == msg.sender, "not your prediction");
        require(!pred.claimed, "already claimed");

        uint256 reward = 0;

        if (pred.pType == PredictionType.SONG_PLAYS) {
            uint256 actualPlays = result.songPlays[pred.songId];
            // 简单规则：误差在 +/-10% 获得 2x 奖励
            if (actualPlays >= (pred.targetValue * 90 / 100) && actualPlays <= (pred.targetValue * 110 / 100)) {
                reward = pred.stakeAmount * 2;
            }
        } else if (pred.pType == PredictionType.TOP_SONG) {
            if (result.topSongId == pred.songId) {
                reward = pred.stakeAmount * 2;
            }
        } else if (pred.pType == PredictionType.TOP_N_RANK) {
            uint256 actualPlays = result.songPlays[pred.songId];
            // targetValue 存储 N
            uint256 count = 0;
            for (uint256 i = 1; i < nextSongId; i++) {
                if (result.songPlays[i] > actualPlays) count++;
            }
            if (count < pred.targetValue) {
                reward = pred.stakeAmount * 2;
            }
        }

        if (reward > 0) {
            require(stakingToken.transfer(pred.user, reward), "transfer failed");
        }

        pred.claimed = true;
        emit RewardClaimed(pred.user, reward);
    }
}
