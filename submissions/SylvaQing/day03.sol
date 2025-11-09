// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract PollStation{
    //最初版本

    // string [] public candidateNames;
    // mapping(string => uint256) voteCount;

    // //添加
    // function addCandidateNames(string memory _candidateName) public {
    //     candidateNames.push(_candidateName);
    //     voteCount[_candidateName]=0;
    // }
    // // 获取
    // function getCandidateNames() public view returns (string[] memory){
    //     return candidateNames;
    // }
    // //投票
    // function vote(string memory _candidateName) public {
    //     voteCount[_candidateName]+=1;
    // }
    // //获取投票
    // function getVote(string memory _candidateName) public view returns (uint256){
    //     return voteCount[_candidateName];
    // }
    
    //优化版本
    //结构体
    struct Candidate{
        string name;
        uint256 votes;
    }
    Candidate[] public candidates;
    //检查是否有重复
    mapping (string=>bool) private candidateExists;
    mapping (address=>bool) private hasVoted;

    //事件注册
    event CandidateAdded (string name);
    event Voted(address indexed voter,string candidate);

    //候选人添加
    function addCandidate(string memory _name) external {
        require(!candidateExists[_name],"candidate already exists"); //检查是否有重复)
        candidates.push(Candidate(_name, 0));
        candidateExists[_name] = true;
        emit CandidateAdded(_name);
    }
    //获取所有获选人名字
    function getCanNames() external view returns (string[] memory){
        string [] memory names=new string [](candidates.length);
        for(uint256 i=0;i<candidates.length;i++){
            names[i]=candidates[i].name;
        }
        return names;
    }

    //投票
    function vote(string memory _name) external {
        require(!hasVoted[msg.sender],"you has already voted");
        require(candidateExists[_name],"Candidate not found");
        for(uint256 i=0;i<candidates.length;i++){
            if(keccak256(bytes(candidates[i].name))== keccak256(bytes(_name))){
                candidates[i].votes+=1;
                hasVoted[msg.sender]=true;
                emit Voted(msg.sender, _name);
                return ;
            }
        }
    }

    //查询选票
    function getVotes(string memory _name) external view returns (uint256){
        require(!candidateExists[_name],"Candidate not exists!!!");
        for(uint256 i=0;i<candidates.length;i++){
            if(keccak256(bytes(candidates[i].name))==keccak256(bytes(_name))){
                return candidates[i].votes;
            }
        }
        
        return 0;
    }
}