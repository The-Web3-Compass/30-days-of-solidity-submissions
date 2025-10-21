// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockWeatherOracle is AggregatorV3Interface, Ownable {  //当前合约继承了两个合约，一个是接口一个是管理权限
    uint8 private _decimals;   //定义小数位数变量记录数据的小数位数，因为solidity不能处理小数，需要人为辨别
    string private _description; //描述变量储存的是给Oracle 数据源加上的人类能看懂的名字或用途说明，方便前端显示、后台识别、合约管理
    uint80 private _roundId;   //储存每次预言机更新数据时的次数序号，记录这是第几次更新的数据有以下用处：
    /*①识别数据是否为最新一轮的数据
    ②审核多个合约同时读取Oracle数据时是否为同一轮数据，确保一致性
    ③方便调取某一轮数据
    ④方便前端页面绘制历史曲线
    ⑤实现chainlink标准接口强制要求有roundID的标准*/
    uint256 private _timestamp;  //数据更新时的时间戳。时间戳记录的是UNIX时间，即从1970年1月1日00：00：00UTC到现在的秒数。（UTC是世界标准时间）
    /*注意：block.timestamp由于为了避免网络不同步或时间精度等因素的影响而被允许有小范围内的偏移秒数，若人为填入时间戳信息是有被任意篡改的风险，因此不能将时间戳用于非常精确或公平的场景*/
    uint256 private _lastUpdateBlock; //上一次数据更新时的区块高度。记录区块高度可以判断距离上次更新过去了多少区块，用来在链上实现伪随机性、限速更新、数据刷新间隔控制等功能

    //初始化第一轮数据
    constructor() Ownable(msg.sender) { //这里涉及引用Ownable合约的构造函数，传入msg.sender直接定死传入的值
        _decimals = 0; // 说明降雨量的值是一个整数，没有小数位数
        _description = "MOCK/RAINFALL/USD"; //模拟/降雨量/USD
        _roundId = 1; //第一次更新数据
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number; //使用block.number记录当前区块高度
    }
    /*合约要继承父合约的构造函数时的语法结构：
    contract Child is Parent {
    constructor(<子构造参数>) Parent(<父构造参数>) {
        // 子构造逻辑
      }
   }
   父构造的参数也可由子构造参数传给：constructor（类型 memory 变量名）父合约（同一变量名）
   直接从父构造传入参数constructor（）父合约（参数）*/ //参数可以是变量，也可以是某一字面量直接定死


    //实现Chainlink所需函数
    //①确定数据小数位数
    function decimals() external view override returns (uint8) {  //override代表重写接口中的函数。
        return _decimals;
    }
    /*在 Solidity 中，重写（override）接口函数时，函数名、参数列表（参数名字可不同）、返回值类型和顺序必须完全一致，
    但你可以自由更改函数体内容、添加额外的修饰符（如 onlyOwner）或更具体的可见性（如从 external 改为 public，但这两不能逆着改）。*/
    
    //②返回Oracle的描述信息
    function description() external view override returns (string memory) {
        return _description;
    }
    
    //③返回接口版本号
    function version() external pure override returns (uint256) {
        return 1;
    }
    
    //④返回某一轮次的天气数据
    function getRoundData(uint80 _roundId_)  //_roundId_：想要查询的某一轮次
        external
        view
        override
        /*返回值声明中的变量名是可选的“命名注释”，对函数运行没有影响，但对合约的可读性、ABI、前端交互界面都有帮助。
        帮助向人类展示具体返回值到底是谁的数据，相当于数据归类
        roundId：用户想要查看的轮次
        answer：回答（比如价格、天气值）
        startedAt：请求数据时开始的时间（预期开始采集）
        updatedAt：数据真正上传并确认的时间（实际获得数据的时间）
        answeredInRound：机器实际返回的轮次*/
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {   //return里变量起到储存真实值的作用，把具体数据归类分给“命名注释”
        return (_roundId_, _rainfall(), _timestamp, _timestamp, _roundId_);
        //因网络延迟或节点响应慢等原因，roundId和answeredInRound（这里默认都是_roundId_），startedAt和answeredInRound(这里默认都是_timestamp)的值会不一致。
    }
    /*returns带变量名但函数体里不用return而直接给参数变量名赋值的例子：
    function getInfo() public pure returns (uint256 id, string memory name) {
    id = 1;
    name = "Alice";
    // 不用 return，自动返回声明的变量（语法糖）
    }
    */
    
    //⑤返回最新一轮数据
    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, _rainfall(), _timestamp, _timestamp, _roundId);
    }


    //模拟生成降雨量的内部函数
    function _rainfall() public view returns (int256) {
        // 使用三个可变动的区块链信息值产生伪随机因素数据
        uint256 blocksSinceLastUpdate = block.number - _lastUpdateBlock;  //blocksSinceLastUpdate：距离上次更新经过了多少个区块
        //用 keccak256 生成一个大数字（32字节的哈希）
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(   //abi.encodePacked(...)：打包多个变量为 bytes，为 keccak256 做准备
            block.timestamp,  //变动值，指现在的时间
            block.coinbase,  //当前出块矿工或验证者的地址，使用这个是为了给每个区块增加“个性”，增强不可预测性。
            blocksSinceLastUpdate //也是一个变动值，避免连号出现重复
        ))) % 1000; // X % 1000 的意思是：“把整数 X 除以 1000，只取余数，余数的范围自然就是0~999.（余数永远必须小于除数 B，不能等于或大于！否则就还能再除一次。）
        /*  表达式        输出范围      
            X % 10       0 ~ 9
            X % 6        0 ~ 5   
            X % 1000     0 ~ 999

        */
        // 将0~999随机数字当作随机降雨量返回
        return int256(randomFactor);
    }
    /*🚫 安全提醒：这不是“真正”的随机数！
    在 Solidity 中：这类方法只能叫“伪随机”，因为矿工 可以提前预测哈希结果，或在某些场景下控制 block.timestamp 等变量
    所以：
    场景	               是否推荐这种方式
    小游戏（本地生成天气）	✅ 可以接受
    赌博类合约 / 重要抽奖	❌ 不安全，必须用 Chainlink VRF（真正随机）*/

    //内部逻辑函数：更新降雨量数据
    function _updateRandomRainfall() private {
        _roundId++;
        _timestamp = block.timestamp;
        _lastUpdateBlock = block.number;
    }

    //外部接口函数：任何人都可以调用它，触发更新降雨量数据。
    function updateRandomRainfall() external {
        _updateRandomRainfall();
        
    }
 /*
✅ 分开写（接口函数 + 内部逻辑函数）的 5 大好处：
序号	好处	    解释
①	   更安全	   内部逻辑函数设为 private/internal，外部无法直接调用，防止绕过权限控制或破坏状态。
②	   更灵活	   外部函数可以加权限（如 onlyOwner）、限制条件、事件日志，而不影响底层逻辑。
③	   更复用	   内部函数可以在多个地方使用，不依赖于是否公开给外部调用者。
④	   更清晰	   命名规范（如 _xxx）和可见性（private/internal）让读代码的人一眼知道“哪些是外部接口”“哪些是内部工具”。
⑤	   更易维护    当需求变化时，只需修改接口函数逻辑，不必重写底层数据更新逻辑，职责清晰、易于调试。*/

}

//这个合约根本没有建立 roundId 到数据 的映射，查任何轮次，它都返回当前的模拟数据，没有办法真正“还原历史数据”

