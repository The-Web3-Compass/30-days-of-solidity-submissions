// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollStation {
    enum Candidate { X, Y }
    enum VoteStatus { NotVoted, VotedValid, VotedInvalid }

    struct Policy {
        uint256 id;
        string description;
        Candidate owner;
    }

    Policy[] private policies;
    mapping(address => VoteStatus) public voteStatus; // @dev 记录每个投票地址的投票状态。
                                                        // @dev 调试示例: `contract.voteStatus("0xYourAddress")`
                                                        // @dev 输出含义: 返回一个uint8值，表示投票状态。0为NotVoted，1为VotedValid，2为VotedInvalid。
    mapping(address => Candidate) public votedFor;     // @dev 记录每个投票地址最终支持的候选人。
                                                        // @dev 调试示例: `contract.votedFor("0xYourAddress")`
                                                        // @dev 输出含义: 返回一个uint8值，表示候选人。0为Candidate.X，1为Candidate.Y。
    mapping(Candidate => uint256) public voteCount;     // @dev 统计每位候选人获得的有效票数。
                                                        // @dev 调试示例: `contract.voteCount(0)` (查询Candidate.X的票数) 或 `contract.voteCount(1)` (查询Candidate.Y的票数)
                                                        // @dev 输出含义: 返回一个uint256值，表示对应候选人的总票数。
    mapping(bytes32 => uint256) private policyDescriptionHashToId; // @dev 将政见描述的keccak256哈希值映射到对应的政见ID
    mapping(bytes32 => bool) private policyDescriptionExists; // @dev 新增：判断政见描述哈希是否存在。

    constructor() {
        // 初始化x候选人的政见
        policies.push(Policy(0, "Lower taxes for corporations", Candidate.X));
        policyDescriptionHashToId[keccak256(abi.encodePacked("Lower taxes for corporations"))] = 0; // @dev 存储政见描述哈希与ID的映射
        policyDescriptionExists[keccak256(abi.encodePacked("Lower taxes for corporations"))] = true; // @dev 标记政见描述存在
        policies.push(Policy(1, "Build stronger national borders", Candidate.X));
        policyDescriptionHashToId[keccak256(abi.encodePacked("Build stronger national borders"))] = 1;
        policyDescriptionExists[keccak256(abi.encodePacked("Build stronger national borders"))] = true;
        policies.push(Policy(2, "Prioritize American energy independence", Candidate.X));
        policyDescriptionHashToId[keccak256(abi.encodePacked("Prioritize American energy independence"))] = 2;
        policyDescriptionExists[keccak256(abi.encodePacked("Prioritize American energy independence"))] = true;

        // 初始化y候选人的政见
        policies.push(Policy(3, "Expand healthcare access", Candidate.Y));
        policyDescriptionHashToId[keccak256(abi.encodePacked("Expand healthcare access"))] = 3;
        policyDescriptionExists[keccak256(abi.encodePacked("Expand healthcare access"))] = true;
        policies.push(Policy(4, "Invest in renewable energy", Candidate.Y));
        policyDescriptionHashToId[keccak256(abi.encodePacked("Invest in renewable energy"))] = 4;
        policyDescriptionExists[keccak256(abi.encodePacked("Invest in renewable energy"))] = true;
        policies.push(Policy(5, "Strengthen social justice policies", Candidate.Y));
        policyDescriptionHashToId[keccak256(abi.encodePacked("Strengthen social justice policies"))] = 5;
        policyDescriptionExists[keccak256(abi.encodePacked("Strengthen social justice policies"))] = true;
    }

    /**
     * @dev 获取所有政见的描述列表。不暴露政见ID和候选人信息。
     * 前端可以根据此列表随机排序展示给用户。
     * @return descriptions 政见的描述字符串数组。
     */
    function getPolicyDescriptions() external view returns (string[] memory) {
        string[] memory descriptions = new string[](policies.length);
        for (uint i = 0; i < policies.length; i++) {
            descriptions[i] = policies[i].description;
        }
        return descriptions;
    }

    /**
     * @dev 用户对一个或多个政见进行投票。投票成功或作废后，该地址将不能再次投票。
     * @param selectedPolicyDescriptions 用户选择的政见描述数组。
     * @notice 投票前必须未投票过。
     * @notice 必须选择至少一个政见。
     * @notice 所有选择的政见必须属于同一位候选人，否则投票作废。
     *
     * @dev 调试输入示例:
     *   有效投票 (所有政见属于 Candidate.X):
     *     ["Lower taxes for corporations", "Build stronger national borders"]
     *   有效投票 (所有政见属于 Candidate.Y):
     *     ["Expand healthcare access"]
     *   无效投票 (政见属于不同候选人):
     *     ["Lower taxes for corporations", "Expand healthcare access"]
     */
    function vote(string[] calldata selectedPolicyDescriptions) external {
        require(voteStatus[msg.sender] == VoteStatus.NotVoted, "Already voted");

        require(selectedPolicyDescriptions.length > 0, "Must select at least one policy");

        // @dev 获取第一个政见的描述哈希和对应的候选人
        bytes32 firstPolicyHash = keccak256(abi.encodePacked(selectedPolicyDescriptions[0]));
        // @dev 确保第一个政见描述有效且存在
        require(policyDescriptionExists[firstPolicyHash], "Invalid policy description");
        Candidate firstCandidate = policies[policyDescriptionHashToId[firstPolicyHash]].owner;

        // @dev 检查所有选定的政见是否都属于同一位候选人
        for (uint i = 1; i < selectedPolicyDescriptions.length; i++) {
            bytes32 currentPolicyHash = keccak256(abi.encodePacked(selectedPolicyDescriptions[i]));
            // @dev 确保当前政见描述有效且存在
            require(policyDescriptionExists[currentPolicyHash], "Invalid policy description");
            if (policies[policyDescriptionHashToId[currentPolicyHash]].owner != firstCandidate) {
                voteStatus[msg.sender] = VoteStatus.VotedInvalid; // @dev 如果有不同候选人的政见，则投票作废
                return;
            }
        }

        // @dev 所有政见归属一致，投票成功
        voteStatus[msg.sender] = VoteStatus.VotedValid;
        votedFor[msg.sender] = firstCandidate;
        voteCount[firstCandidate]++;
    }

    // 可选：获取政见总数
    function getPolicyCount() external view returns (uint256) {
        return policies.length;
    }
}
