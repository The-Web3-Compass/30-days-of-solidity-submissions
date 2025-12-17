//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedGovernance is ReentrancyGuard {
    //声明对 uint256 类型启用 SafeCast 库的功能
    //允许在 uint256 类型上直接调用 SafeCast 提供的安全转换方法
    using SafeCast for uint256;

    //定义一个结构体（struct）类型，名为 Proposal（提案）
    struct Proposal {
        uint256 id;     //提案的唯一编号。方便根据编号查找、存储和追踪提案
        string description;     //提案的文字说明或内容
        uint256 deadline;     //记录该提案投票截止的时间点（区块时间戳）
        uint256 votesFor;     //记录支持票的总数
        uint256 votesAgainst;     //记录反对票的总数
        bool executed;     //标记提案是否已被执行
        address proposer;     //记录提出这个提案的账户地址
        bytes[] executionData;     //保存提案要执行的函数调用数据（可以有多个）
        address[] executionTargets;     //保存提案要调用的目标合约地址
        uint256 executionTime;     //提案可以被执行的时间点（加入时间锁之后的具体时间）
    }

    //用于治理投票的代币（治理代币）
    IERC20 public governanceToken;
    //创建一个映射（哈希表），将提案编号映射到 Proposal 结构体
    mapping(uint256 => Proposal) public proposals;
    //“嵌套映射”，外层 key 是提案 ID，内层 key 是投票人地址，值是布尔值
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    //记录下一个提案的编号
    uint256 public nextProposalId;
    //定义每个提案的投票持续时间（以秒为单位）
    uint256 public votingDuration;
    //定义提案在通过后、正式执行前的时间锁时长（秒）
    uint256 public timelockDuration;
    //定义一个管理员地址
    address public admin;
    //设置初始法定投票率为 5%
    uint256 public quorumPercentage = 5;
    //定义提案保证金数量，默认为 10 个代币
    uint256 public proposalDepositAmount = 10;

    //用于记录链上日志
    event ProposalCreated(uint256 id, string description, address proposer, uint256 depositAmount);
    //投票事件，记录某个地址投了哪份提案、支持还是反对、以及票权权重
    event Voted(uint256 proposalId, address voter, bool support, uint256 weight);
    //提案执行事件，表示该提案是否最终通过
    event ProposalExecuted(uint256 id, bool passed);
    //表示某个提案未达到法定投票率（投票人数不够）
    event QuorumNotMet(uint256 id, uint256 votesTotal, uint256 quorumNeeded);
    //记录提案人支付保证金的事件
    event ProposalDepositPaid(address proposer, uint256 amount);
    //记录提案成功后退还保证金的事件
    event ProposalDepositRefunded(address proposer, uint256 amount);
    //记录管理员修改时间锁时长的事件
    event TimelockSet(uint256 duration);
    //表示某个提案通过后，时间锁倒计时已经开始
    event ProposalTimelockStarted(uint256 proposalId, uint256 executionTime);

    //用于限制某些函数只有管理员可以调用
    modifier onlyAdmin() {
        //判断当前调用者是不是管理员地址
        require(msg.sender == admin, "Only admin can call this");
        _;
    }

    //定义合约的构造函数，用于在部署时初始化关键参数
    constructor(address _governanceToken, uint256 _votingDuration, uint256 _timelockDuration) {
        //将传入的 _governanceToken 地址转换为 IERC20 接口对象，并保存到合约的 governanceToken 变量中
        governanceToken = IERC20(_governanceToken);
        //设置提案投票的持续时间（单位：秒）
        votingDuration = _votingDuration;
        //设置提案执行前的时间锁时长
        timelockDuration = _timelockDuration;
        //将部署合约的钱包地址设为管理员
        admin = msg.sender;
        //在部署时就触发一个事件，记录设置的时间锁时长
        emit TimelockSet(_timelockDuration);
    }

    //定义一个公开函数，用来修改法定投票率
    function setQuorumPercentage(uint256 _quorumPercentage) external onlyAdmin {
        //确保法定比例数值合理（0~100%）
        require(_quorumPercentage <= 100, "Quorum percentage must be between 0 and 100");
        //更新全局变量 quorumPercentage 的值
        quorumPercentage = _quorumPercentage;
    }

    //定义函数，用来修改“提案保证金”的金额
    //管理员可以根据治理活跃度调整提案成本，防止滥提或鼓励参与
    function setProposalDepositAmount(uint256 _proposalDepositAmount) external onlyAdmin {
        //更新全局变量中的保证金数额
        proposalDepositAmount = _proposalDepositAmount;
    }

    //管理员函数，用来修改时间锁的持续时长
    function setTimelockDuration(uint256 _timelockDuration) external onlyAdmin {
        //将新的时间锁值存入变量
        timelockDuration = _timelockDuration;
        //触发事件，记录修改动作
        emit TimelockSet(_timelockDuration);
    }

    //定义创建提案的函数。调用者提交提案描述、目标合约地址数组、执行数据数组
    function createProposal(
        //写提案的文字说明
        string calldata _description,
        //指定提案要调用的合约或账户地址列表
        address[] calldata _targets,
        //每一项包含“要发送给对应 _targets[i] 的 calldata”
        bytes[] calldata _calldatas
    ) external returns (uint256) {
        //要求调用者必须持有足够的治理代币，数量至少等于提案保证金
        require(governanceToken.balanceOf(msg.sender) >= proposalDepositAmount, "Insufficient tokens for deposit");
        //确保 _targets 与 _calldatas 两个数组长度一致；如果不一致则回退
        //保证在执行时每个目标地址都有对应的一份 calldata，避免执行时索引越界或错配导致不可预期的行为
        require(_targets.length == _calldatas.length, "Targets and calldatas length mismatch");

        //把 proposalDepositAmount 个代币从提案者（msg.sender）转到本合约地址（address(this)）
        governanceToken.transferFrom(msg.sender, address(this), proposalDepositAmount);
        //在链上发出一个事件（日志），说明提案者已支付保证金及其金额
        emit ProposalDepositPaid(msg.sender, proposalDepositAmount);

        //正在把一个新的 Proposal 结构体写入到 proposals 映射里，使用 nextProposalId 作为键
        //在链上记录提案信息（把提案永久保存到区块链状态）
        proposals[nextProposalId] = Proposal({
            //把结构体的 id 字段设置为 nextProposalId（当前要分配的编号）
            //明确这个提案的编号等于映射的键，便于索引与返回
            id: nextProposalId,
            //把外部传入的 _description 文本保存到结构体的 description 字段
            description: _description,
            //设置 deadline（投票截止）为当前区块时间 block.timestamp 加上预先设定的 votingDuration
            //定义投票开放期，从创建时间开始到 deadline 为止，任何人在此期间都可以投票（满足其他条件）
            deadline: block.timestamp + votingDuration,
            //把 votesFor 字段初始化为 0（当前没有支持票）
            votesFor: 0,
            //把 votesAgainst 字段初始化为 0（当前没有反对票）
            votesAgainst: 0,
            //把 executed 标记为 false（表示尚未执行或结束）
            executed: false,
            //记录发起提案者地址（谁提交的提案）
            proposer: msg.sender,
            //保存所有要执行的 ABI 编码数据
            executionData: _calldatas,
            //保存提案中每个要调用的目标地址，与 executionData 一一对应
            executionTargets: _targets,
            //初始化 executionTime 为 0，表示还未设置可执行时间（timelock 尚未开始）
            executionTime: 0
        });

        //触发 ProposalCreated 事件，包含刚创建提案的 ID、描述、提案者地址与押金金额
        emit ProposalCreated(nextProposalId, _description, msg.sender, proposalDepositAmount);

        //计数器 nextProposalId 自增 1，为下次创建提案准备新的 ID
        //保证每个提案有唯一、不重复的编号
        nextProposalId++;
        //函数返回刚刚创建的提案 ID
        return nextProposalId - 1;
    }

    //定义一个公开函数 vote，用来对指定提案进行投票
    //让代币持有人对某个提案进行投票
    function vote(uint256 proposalId, bool support) external {
        //从存储中读取对应编号的提案
        Proposal storage proposal = proposals[proposalId];
        //检查当前时间是否在投票截止时间前
        require(block.timestamp < proposal.deadline, "Voting period over");
        //确保投票者持有治理代币
        require(governanceToken.balanceOf(msg.sender) > 0, "No governance tokens");
        //确保用户还没对该提案投过票
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        //记录投票权重
        uint256 weight = governanceToken.balanceOf(msg.sender);

        //根据 support 的值决定加到“赞成票”或“反对票”
        if (support) {
            proposal.votesFor += weight;
        } else {
            proposal.votesAgainst += weight;
        }

        //标记该用户已投票
        hasVoted[proposalId][msg.sender] = true;

        //触发 Voted 事件，在链上记录每次投票信息
        emit Voted(proposalId, msg.sender, support, weight);
    }

    //定义一个公开函数，用于投票结束后处理提案
    //计算提案是否通过，并决定是否进入时间锁阶段
    function finalizeProposal(uint256 proposalId) external {
        //从存储中获取对应提案的完整信息
        Proposal storage proposal = proposals[proposalId];
        //确保投票时间已结束
        require(block.timestamp >= proposal.deadline, "Voting period not yet over");
        //确保提案尚未执行过
        require(!proposal.executed, "Proposal already executed");
        //确保还没有设置执行时间
        require(proposal.executionTime == 0, "Execution time already set");

        //获取治理代币的总供应量
        uint256 totalSupply = governanceToken.totalSupply();
        //计算该提案总投票数（赞成+反对）
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        //计算提案需要的最低投票数
        uint256 quorumNeeded = (totalSupply * quorumPercentage) / 100;

        //检查：1）总投票数是否达标，2）赞成票是否多于反对票
        //如果满足这两个条件，提案通过并进入时间锁阶段
        if (totalVotes >= quorumNeeded && proposal.votesFor > proposal.votesAgainst) {
            //设置提案可执行的时间为当前时间 + 时间锁
            proposal.executionTime = block.timestamp + timelockDuration;
            //触发事件，记录提案进入时间锁
            emit ProposalTimelockStarted(proposalId, proposal.executionTime);
        } else {
            //标记提案已执行（失败也算执行完成）
            proposal.executed = true;
            //触发事件，表示提案执行失败
            emit ProposalExecuted(proposalId, false);
            //如果总票数未达到法定人数，触发 QuorumNotMet 事件
            if (totalVotes < quorumNeeded) {
                emit QuorumNotMet(proposalId, totalVotes, quorumNeeded);
            }
        }
    }

    //定义一个公开函数，用于实际执行通过的提案
    //根据提案内容调用对应的合约方法或操作
    function executeProposal(uint256 proposalId) external nonReentrant {
        //获取对应编号的提案
        Proposal storage proposal = proposals[proposalId];
        //确保该提案还没有执行过
        require(!proposal.executed, "Proposal already executed");
        //确保提案已设置执行时间，并且当前时间超过时间锁
        require(proposal.executionTime > 0 && block.timestamp >= proposal.executionTime, "Timelock not yet expired");

        //先标记提案为已执行
        proposal.executed = true; 

        //判断提案是否通过
        bool passed = proposal.votesFor > proposal.votesAgainst;

        //如果提案通过，则执行提案操作
        if (passed) {
            //遍历提案中所有要执行的目标地址
            for (uint256 i = 0; i < proposal.executionTargets.length; i++) {
                //对第 i 个目标执行低级 call 操作
                (bool success, bytes memory returnData) = proposal.executionTargets[i].call(proposal.executionData[i]);
                //如果执行失败，则回滚交易
                require(success, string(returnData));
            }
            //发出事件，表示提案执行成功
            emit ProposalExecuted(proposalId, true);
            //将提案保证金退还给提案人
            governanceToken.transfer(proposal.proposer, proposalDepositAmount);
            //触发事件，记录提案保证金已退还
            emit ProposalDepositRefunded(proposal.proposer, proposalDepositAmount);
        //如果提案未通过，则发出失败事件
        } else {
            emit ProposalExecuted(proposalId, false);
        }
    }

    //定义一个只读函数，用于获取提案的最终结果（文字描述）
    function getProposalResult(uint256 proposalId) external view returns (string memory) {
        //获取指定编号的提案数据
        Proposal storage proposal = proposals[proposalId];
        //确保提案已被执行（或失败标记）
        require(proposal.executed, "Proposal not yet executed");

        //重新计算：
        uint256 totalSupply = governanceToken.totalSupply();     //代币总供应量
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;     //总投票数
        uint256 quorumNeeded = (totalSupply * quorumPercentage) / 100;     //法定票数

        //如果总票数未达到法定票数，返回“失败-未达法定人数”
        //明确提案失败原因
        if (totalVotes < quorumNeeded) {
            return "Proposal FAILED - Quorum not met";
        //如果赞成票多于反对票，返回“通过”
        } else if (proposal.votesFor > proposal.votesAgainst) {
            return "Proposal PASSED";
        //否则返回“被否决”
        //表示提案未通过，但达到法定人数
        } else {
            return "Proposal REJECTED";
        }
    }

    //定义一个只读函数，用于返回提案的完整信息
    function getProposalDetails(uint256 proposalId) external view returns (Proposal memory) {
        //返回指定编号的提案数据
        return proposals[proposalId];
    }
}