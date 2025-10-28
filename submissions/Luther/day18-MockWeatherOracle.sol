//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Chainlink 官方的标准预言机接口
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// OpenZeppelin 的一个辅助函数，它赋予我们所有权功能，包括 `owner()` 和 `onlyOwner` 修饰符
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockWeatherOracle is AggregatorV3Interface, Ownable {
    uint8 private _decimals;     //数据精度，小数位数。这里设为 0
    string private _description;     //数据源描述
    uint80 private _roundId;     //模拟不同的数据更新轮次（round），每次更新递增。
    uint256 private _timestamp;     //记录上一次更新的时间戳（秒）
    uint256 private _lastUpdateBlock;     //上次更新所在区块号，用来生成随机数
    // PsPs: private 修饰符，只能在合约内部使用。外部合约若要获取信息，必须通过 AggregatorV3Interface 的接口函数

    constructor() Ownable(msg.sender) {     //调用 Ownable 构造函数，把部署者设为 owner（管理员）
        _decimals = 0;      //降雨量以“整毫米”为单位
        _description = "MOCK/RAINFALL/USD";     //为这个伪造的数据源添加标识
        _roundId = 1;     //初始轮次编号为 1

        //记录当前时间和区块号，用于生成伪随机数据。
        _timestamp = block.timestamp;     
        _lastUpdateBlock = block.number;
    }

    //让外部应用知道，这个数据没有小数部分
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    //提供可读的标识信息，让外部知道这是啥数据
    function description() external view override returns (string memory) {
        return _description;
    }

    //方便开发者识别当前合约版本,返回预言机的版本号
    function version() external pure override returns (uint256) {
        return 1;
    }

    //这是 Chainlink 接口的标准函数之一
    //用来获取“指定轮次（roundId）”的数据
    function getRoundData(uint80 _roundId_)
        external
        view
        override
        returns (
            uint80 roundId,     //传进来的轮次编号
            int256 answer,     //模拟的降雨量数据（0~999 毫米）
            uint256 startedAt, 
            uint256 updatedAt, 
            uint80 answeredInRound)
    {
        return (_roundId_, _rainfall(), _timestamp, _timestamp, _roundId_);
    }


    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, _rainfall(), _timestamp, _timestamp, _roundId);
    }

    function _rainfall() public view returns (int256) {
        uint256 blocksSinceLastUpdate = block.number - _lastUpdateBlock;
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.coinbase,
            blocksSinceLastUpdate
        ))) % 1000; 

        return int256(randomFactor);


function _updateRandomRainfall() private {
        _roundId++;     //对合约存储变量 _roundId 做自增操作
        _timestamp = block.timestamp;     //把当前区块时间戳（单位秒）写入 _timestamp（uint256）
        _lastUpdateBlock = block.number;     //把当前区块号写入 _lastUpdateBlock
    }

    //对外暴露的函数（没有 view 或 pure），意味着它会发起交易（如果被调用以修改状态），只能通过交易（签名）执行
    function updateRandomRainfall() external {

        //调用上文的 private 函数，执行 _roundId++、更新时间戳、更新 _lastUpdateBlock
        _updateRandomRainfall();
    }
}