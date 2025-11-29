     
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";// ERC-20 代币的接口
import "@openzeppelin/contracts/utils/math/SafeCast.sol";//进行安全的类型转换
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";//这增加了对称为重入攻击的讨厌类别攻击的保护

/// @title Decentralized Governance System (ERC-20 Based)
/// @notice A DAO with weighted voting, quorum, proposal deposit, and timelock.
contract DecentralizedGovernance is ReentrancyGuard {//继承自  ReentrancyGuar
    using SafeCast for uint256;//继承自  ReentrancyGuar

    struct Proposal {
        uint256 id;//用于跟踪的唯一 ID 号
        string description;//对提案内容的人类可读解释
        uint256 deadline;//投票结束时的时间戳标记
        uint256 votesFor;//有多少票投了赞成票
        uint256 votesAgainst;//有多少票投了反对票
        bool executed;//一个布尔值（true/false），用于跟踪提案是否已执行
        address proposer;//创建提案的人的地址
        bytes[] executionData;//要执行的字节指令（bytes[]）
        address[] executionTargets;//调用合约的目标地址
        uint256 executionTime;//时间锁后提案可以正式执行的未来时间戳
    }

    IERC20 public governanceToken;//代表投票权的 ERC-20 代币
    mapping(uint256 => Proposal) public proposals;//每个 Proposal 结构都通过其唯一 ID 存储和访问
    mapping(uint256 => mapping(address => bool)) public hasVoted;//这使我们能够跟踪特定用户是否已经对特定提案进行了投票。

    uint256 public nextProposalId;//新提案时将分配的下一个 ID 从0开始
    uint256 public votingDuration;//定义了每个提案开放投票的时间 
    uint256 public timelockDuration;//提案获胜后实际执行之前的等待期
    address public admin;//存储了管理员地址 部署合约的钱包
    uint256 public quorumPercentage = 5;//少有 5%必须参与
    uint256 public proposalDepositAmount = 10;//抵押锁定governance token

    event ProposalCreated(uint256 id, string description, address proposer, uint256 depositAmount);//每当创建新提案时
    event Voted(uint256 proposalId, address voter, bool support, uint256 weight);//每当有人投票时
    event ProposalExecuted(uint256 id, bool passed);//提案已执行
    event QuorumNotMet(uint256 id, uint256 votesTotal, uint256 quorumNeeded);//法定人数未满足
    event ProposalDepositPaid(address proposer, uint256 amount);//提案定金已付
    event ProposalDepositRefunded(address proposer, uint256 amount);//提案定金已退还
    event TimelockSet(uint256 duration);//时间锁设定
    event ProposalTimelockStarted(uint256 proposalId, uint256 executionTime);//提案时间锁已开始

    modifier onlyAdmin() {//仅限管理员访问
        require(msg.sender == admin, "Only admin can call this");
        _;
    }

    constructor(address _governanceToken, uint256 _votingDuration, uint256 _timelockDuration) {
        governanceToken = IERC20(_governanceToken);//治理投票的 ERC-20 代币的地址
        votingDuration = _votingDuration;//设置了每个提案将保持开放投票的秒数 
        timelockDuration = _timelockDuration;//强制等待时间 在提案获胜和实际执行之间
        admin = msg.sender;//部署合同的人员将成为管理员 。
        emit TimelockSet(_timelockDuration);//发出一个事件 ，向世界宣布时间锁设置
    }

    function setQuorumPercentage(uint256 _quorumPercentage) external onlyAdmin {//设置仲裁百分比
        require(_quorumPercentage <= 100, "Quorum percentage must be between 0 and 100");//新法定人数必须介于 0% 到 100% 之间 
        quorumPercentage = _quorumPercentage;//新的 quorumPercentage 将应用于所有未来的提案
    }

    function setProposalDepositAmount(uint256 _proposalDepositAmount) external onlyAdmin {//设置提案存款金额
        proposalDepositAmount = _proposalDepositAmount;
    }

    function setTimelockDuration(uint256 _timelockDuration) external onlyAdmin {//更新时间锁持续时间 
        timelockDuration = _timelockDuration;
        emit TimelockSet(_timelockDuration);
    }

    function createProposal(//创建提案
        string calldata _description,//描述
        address[] calldata _targets,//该提案将与之交互的合约地址（如果通过）
        bytes[] calldata _calldatas//将发送到每个目标的实际函数调用数据
    ) external returns (uint256) {
        require(governanceToken.balanceOf(msg.sender) >= proposalDepositAmount, "Insufficient tokens for deposit");
        //检查用户是否有足够的token
        require(_targets.length == _calldatas.length, "Targets and calldatas length mismatch");
        //确保目标和调用数据匹配
       /* (bool success, bytes memory reason) = address(governanceToken).call(
    abi.encodeWithSelector(
        governanceToken.transferFrom.selector, 
        msg.sender, 
        address(this), 
        proposalDepositAmount));
// 如果 transferFrom 失败，则打印一个明确的错误信息
require(success, string(reason)); // 这将把代币合约内部的 revert 消息暴露出来！*/

        governanceToken.transferFrom(msg.sender, address(this), proposalDepositAmount);
        //收取提案押金
        emit ProposalDepositPaid(msg.sender, proposalDepositAmount);

        proposals[nextProposalId] = Proposal({//保存新提案
            id: nextProposalId,
            description: _description,
            deadline: block.timestamp + votingDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            proposer: msg.sender,
            executionData: _calldatas,
            executionTargets: _targets,
            executionTime: 0
        });

        emit ProposalCreated(nextProposalId, _description, msg.sender, proposalDepositAmount);

        nextProposalId++;//更新提案计数器
        return nextProposalId - 1;
    }

    function vote(uint256 proposalId, bool support) external {//投票函数
        Proposal storage proposal = proposals[proposalId];//加载提案
        require(block.timestamp < proposal.deadline, "Voting period over");//确保投票仍然开放
        require(governanceToken.balanceOf(msg.sender) > 0, "No governance tokens");//确保用户持有治理代币
        require(!hasVoted[proposalId][msg.sender], "Already voted");//防止重复投票

        uint256 weight = governanceToken.balanceOf(msg.sender);//计算投票权

        if (support) {
            proposal.votesFor += weight;//如果支持的话就把投票权重加到支持中
        } else {
            proposal.votesAgainst += weight;//如果反对就把投票权重加到反对中
        }

        hasVoted[proposalId][msg.sender] = true;//将用户标记为已投票

        emit Voted(proposalId, msg.sender, support, weight);//发出投票事件
    }

    function finalizeProposal(uint256 proposalId) external {//敲定提案
        Proposal storage proposal = proposals[proposalId];//加载提案
        require(block.timestamp >= proposal.deadline, "Voting period not yet over");
        //确保投票结束
        require(!proposal.executed, "Proposal already executed");
        //确保尚未最终确定
        require(proposal.executionTime == 0, "Execution time already set");
        //确保它尚未进入时间锁

        uint256 totalSupply = governanceToken.totalSupply();//总共有多少个代币 （totalSupply）
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;//投了多少票 （totalVotes）
        uint256 quorumNeeded = (totalSupply * quorumPercentage) / 100;//需要多少票数（法定人数

        if (totalVotes >= quorumNeeded && proposal.votesFor > proposal.votesAgainst) {
            proposal.executionTime = block.timestamp + timelockDuration;
            //如果有足够多的人投票 **，** 并且**投票赞成**的人多于**反对**的人......然后，提案**进入时间锁定期** 。
            emit ProposalTimelockStarted(proposalId, proposal.executionTime);
        } else {
            proposal.executed = true;//如果提案失败 即将其标记为已执行
            emit ProposalExecuted(proposalId, false);//说提案失败了
            if (totalVotes < quorumNeeded) {//没有足够的选民参与
                emit QuorumNotMet(proposalId, totalVotes, quorumNeeded);//发出一个额外的事件 QuorumNotMet 来解释它失败的确切原因
            }
        }
    }

    function executeProposal(uint256 proposalId) external nonReentrant {//执行提案
        Proposal storage proposal = proposals[proposalId];//加载提案
        require(!proposal.executed, "Proposal already executed");//确保它尚未执行
        require(proposal.executionTime > 0 && block.timestamp >= proposal.executionTime, "Timelock not yet expired");//确保时间锁结束

        proposal.executed = true; // set early to prevent reentrancy案标记为已执行

        bool passed = proposal.votesFor > proposal.votesAgainst;//检查提案是否实际通过

        if (passed) {//执行提案（如果通过）
            for (uint256 i = 0; i < proposal.executionTargets.length; i++) {
                (bool success, bytes memory returnData) = proposal.executionTargets[i].call(proposal.executionData[i]);
                //执行每一个修改直到修改完成
                require(success, string(returnData));
            }
            emit ProposalExecuted(proposalId, true);
            governanceToken.transfer(proposal.proposer, proposalDepositAmount);//转账退回押金
            emit ProposalDepositRefunded(proposal.proposer, proposalDepositAmount);
        } else {
            emit ProposalExecuted(proposalId, false);//发出一个事件 押金  不予退还—
        }
    }

    function getProposalResult(uint256 proposalId) external view returns (string memory) {
        Proposal storage proposal = proposals[proposalId];//加载提案
        require(proposal.executed, "Proposal not yet executed");//确保它已经执行

        uint256 totalSupply = governanceToken.totalSupply();//总共存在多少治理代币
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;//该提案实际投了多少票
        uint256 quorumNeeded = (totalSupply * quorumPercentage) / 100;//提案需要多少票才能被视为有效

        if (totalVotes < quorumNeeded) {//如果参与不足
            return "Proposal FAILED - Quorum not met";//如果没有投出足够的票数（未达到法定人数）
        } else if (proposal.votesFor > proposal.votesAgainst) {//如果通过
            return "Proposal PASSED";//提案顺利通过
        } else {
            return "Proposal REJECTED";//该提案被拒绝 
        }
    }

    function getProposalDetails(uint256 proposalId) external view returns (Proposal memory) {//完整的提案详细
        return proposals[proposalId];
    }
}


