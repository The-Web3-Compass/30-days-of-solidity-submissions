// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title 投票站合约 PollStation.sol
/// @author yuheng
/// @notice 此合约用于添加候选人、进行投票并统计得票数
/// @dev 本合约使用 string 数组和 mapping 来实现基本的投票功能

contract PollStation {
    /// @notice 声明候选人名单和投票跟踪
    string[] public candidateNames;     // 声明数组——存储候选人列表
    mapping(string => uint256) voteCount;       // 存储每个候选人对应的票数
    /*
    @notice 添加新的候选人
    @dev 将姓名加入数组，并初始化其票数为 0
    @param _candidateNames 候选人姓名
    */
    function addCandidateNames(string memory _candidateNames) public{
        candidateNames .push(_candidateNames);  // 向候选人数组末尾添加一个新名字
        voteCount[_candidateNames] = 0;  // 初始化票数为 0
    }

    /*
    @notice 获取当前所有候选人的名字
    @dev view 函数，不消耗 gas（如果外部调用）
    @return 所有候选人姓名的数组
    */
    function getcandidateNames() public view returns (string[] memory) {
        return candidateNames;  // 返回候选人名数组
    }

    /*
    @notice 为指定候选人投票
    @dev 直接增加该候选人对应的票数
    @param _candidateNames 要投票的候选人姓名
    */
    function vote(string memory _candidateNames) public {
        voteCount[_candidateNames] += 1;    //候选人票数 +1
    }
    
    /*
    @notice 获取指定候选人的得票数
    @dev 查询 mapping 中的计票数据
    @param _candidateNames 候选人姓名
    @return 该候选人目前的总票数
    */
    function getVote(string memory _candidateNames) public view returns (uint256){
        return voteCount[_candidateNames];  // 返回指定候选人的票数
    }
}