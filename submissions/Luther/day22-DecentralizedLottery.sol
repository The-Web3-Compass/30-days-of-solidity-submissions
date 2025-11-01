//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//导入 Chainlink VRF 库
//VRFConsumerBaseV2Plus：是 Chainlink 提供的基类，合约继承它后，就可以与 VRF（随机数服务）进行交互
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
//VRFV2PlusClient：是一个辅助库（library），帮你格式化、封装要发送给 Chainlink 的随机数请求
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract FairChainLottery is VRFConsumerBaseV2Plus {

    //定义状态枚举 LOTTERY_STATE，包含三种类型
    //OPEN – 开放状态，允许玩家参加
    //CLOSED – 关闭状态，彩票暂未开启
    //CALCULATING – 正在计算中奖者（等待 Chainlink VRF 返回随机数）
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING }
    //lotteryState 是一个公开变量，用来实时记录彩票当前处于哪种阶段
    LOTTERY_STATE public lotteryState;
    //PsPs：这是整个游戏的“大脑”，防止状态错乱


    //记录玩家与费用
    address payable[] public players;     //players：一个可支付的地址数组，保存所有参与者
    address public recentWinner;     //recentWinner：记录上一次的中奖者
    uint256 public entryFee;     //entryFee：每位玩家进入彩票所需支付的最小 ETH 数额
    //PsPs：这些变量构成了“彩票的数据结构”

    // Chainlink VRF 参数配置
    uint256 public subscriptionId;     //subscriptionId：你的 Chainlink VRF 订阅账户 ID，用于支付随机数费用
    bytes32 public keyHash;     // keyHash：指定使用哪个 VRF oracle job
    uint32 public callbackGasLimit = 100000;     //callbackGasLimit：Chainlink 回调 fulfillRandomWords 时能用的最大 gas
    uint16 public requestConfirmations = 3;     //requestConfirmations：Chainlink 等待的区块确认数
    uint32 public numWords = 1;     //numWords：要请求的随机数个数
    uint256 public latestRequestId;     //latestRequestId：记录上一次请求的 ID
    // 告诉 Chainlink VRF：我要用这个 oracle job，扣我这个订阅的费用，用这么多 gas，帮我生成 1 个随机数。

    //构造函数 — 初始化设置
    //相当于「布置游戏场地」，一切准备完毕后才允许开始
    constructor(
        address vrfCoordinator,
        uint256 _subscriptionId,
        bytes32 _keyHash,
        uint256 _entryFee
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        entryFee = _entryFee;
        lotteryState = LOTTERY_STATE.CLOSED;
    }

    //进入彩票，这是玩家的「购票入口」
    //发送 ETH + 调用该函数 = 拿到一张彩票
    function enter() public payable {
        //只有在 OPEN 状态时才能参加
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        //必须支付至少 entryFee 的 ETH
        require(msg.value >= entryFee, "Not enough ETH");
        //将玩家地址加入 players 列表
        players.push(payable(msg.sender));
    }

    //开启彩票（只能由合约拥有者）
    //控制权限，防止恶意用户乱开或重复开启
    function startLottery() external onlyOwner {
        //只能在彩票关闭时开启
        require(lotteryState == LOTTERY_STATE.CLOSED, "Can't start yet");
        //状态切换为 OPEN
        lotteryState = LOTTERY_STATE.OPEN;
    }

    //结束彩票并请求随机数
    //关闭售票窗口 → 抽签请求发出 → 等待 Chainlink 回调
    function endLottery() external onlyOwner {
        //确认彩票当前为 OPEN
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        //切换状态为 CALCULATING（正在计算)，表示我们已经关闭售票并正在等待 Chainlink 的随机数回应
        lotteryState = LOTTERY_STATE.CALCULATING;
        
        //构造一个 VRF 随机请求
        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            keyHash: keyHash,     //要使用的随机数任务
            subId: subscriptionId,     //付费方
            requestConfirmations: requestConfirmations,     //需要等待多少次确认
            callbackGasLimit: callbackGasLimit,     //响应时消耗多少 gas
            numWords: numWords,     //请求多少个随机数
            //把额外参数序列化为 bytes
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
            )
        });
        //把请求发送到 Chainlink 网络
        latestRequestId = s_vrfCoordinator.requestRandomWords(req);
    }

    //Chainlink 回调函数
    //整个系统的“开奖仪式”，自动、公平、透明
    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        //再次确认当前状态确实在 CALCULATING，防止在错误状态下处理随机数（双重保险）
        require(lotteryState == LOTTERY_STATE.CALCULATING, "Not ready to pick winner");
        
        //把 Chainlink 返回的第一个随机数 randomWords[0] 通过 % players.length（取余）映射到玩家数组的索引范围 [0, players.length-1]
        uint256 winnerIndex = randomWords[0] % players.length;
        //取得赢家地址并把它标记为 payable 以供发送 ETH
        address payable winner = players[winnerIndex];
        //将赢家地址保存到 recentWinner，便于外部查询或前端展示历史赢家
        recentWinner = winner;

        //清空数组并释放存储空间
        delete players;
        //将状态设为 CLOSED，表示本轮已结束，等待所有者再次 startLottery() 开启下一轮
        lotteryState = LOTTERY_STATE.CLOSED;

        //向赢家地址发起原生代币（ETH）转账：把合约当前余额 address(this).balance 全部转给赢家
        (bool sent, ) = winner.call{value: address(this).balance}("");
        //如果转账失败（sent == false），则 revert 整个 fulfillRandomWords，这会回滚写入的状态更改
        require(sent, "Failed to send ETH to winner");
    }

    //查询玩家列表
    //用于前端展示或透明审计
    function getPlayers() external view returns (address payable[] memory) {
        return players;
    }
}
