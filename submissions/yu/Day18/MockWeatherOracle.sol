// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract MockWeatherOracle is AggregatorV3Interface, Ownable {
    uint8 private _decimals;
    string private _description;
    uint80 private _roundId;
    uint256 private _timestamp;
    uint256 private _lastUpdateBlock;
    
    // 存储历史数据
    mapping(uint80 => int256) private _rainfallData;
    
    event RainfallUpdated(uint80 indexed roundId, int256 rainfall, uint256 timestamp);
    
    constructor() Ownable(msg.sender) {
        _decimals = 0; // 降雨量以毫米为单位，不需要小数
        _description = "MOCK/RAINFALL";
        _roundId = 1;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
        
        // 初始化第一个降雨量数据
        _rainfallData[_roundId] = _getRainfall();
    }
    
    function decimals() external view override returns (uint8) {
        return _decimals;
    }
    
    function description() external view override returns (string memory) {
        return _description;
    }
    
    function version() external pure override returns (uint256) {
        return 1;
    }
    
    function getRoundData(uint80 roundId_)
        external
        view
        override
        returns (
            uint80 roundId, 
            int256 answer, 
            uint256 startedAt, 
            uint256 updatedAt, 
            uint80 answeredInRound
        )
    {
        require(_rainfallData[roundId_] != 0 || roundId_ == 1, "No data present");
        return (
            roundId_, 
            _rainfallData[roundId_], 
            _timestamp, 
            _timestamp, 
            roundId_
        );
    }
    
    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId, 
            int256 answer, 
            uint256 startedAt, 
            uint256 updatedAt, 
            uint80 answeredInRound
        )
    {
        return (
            _roundId, 
            _rainfallData[_roundId], 
            _timestamp, 
            _timestamp, 
            _roundId
        );
    }
    
    /**
     * @dev 使用区块信息生成伪随机的降雨量值。
     * 警告：这不适用于生产环境的安全随机数。
     */
    function _getRainfall() internal view returns (int256) {
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao, // 使用 prevrandao 替代 block.difficulty (EIP-4399)
            block.number - _lastUpdateBlock,
            msg.sender
        ))) % 1000; // 随机数范围 0-999
        return int256(randomFactor); // 返回 0 到 999mm 的随机降雨量
    }
    
    /**
     * @dev 任何人都可以调用此函数来强制更新"预言机"数据，以模拟新一轮的数据更新。
     */
    function updateRainfall() external {
        _roundId++;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
        
        // 生成新的降雨量数据
        int256 newRainfall = _getRainfall();
        _rainfallData[_roundId] = newRainfall;
        
        emit RainfallUpdated(_roundId, newRainfall, _timestamp);
    }
    
    /**
     * @dev 管理员手动设置降雨量数据（用于测试）
     * @param rainfall 降雨量数据（毫米）
     */
    function setRainfall(int256 rainfall) external onlyOwner {
        require(rainfall >= 0, "Rainfall cannot be negative");
        _roundId++;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
        
        _rainfallData[_roundId] = rainfall;
        
        emit RainfallUpdated(_roundId, rainfall, _timestamp);
    }
    
    /**
     * @dev 获取当前降雨量（简化接口）
     */
    function getCurrentRainfall() external view returns (int256) {
        return _rainfallData[_roundId];
    }
    
    /**
     * @dev 获取当前轮次ID
     */
    function getCurrentRoundId() external view returns (uint80) {
        return _roundId;
    }
}