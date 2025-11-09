//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

// Write a voting contract that's lean,efficient and cost-effective

// General voting contract
// Unoptimized Version
// contract BasicVoting{
//     struct Proposal{
//         string name;
//         uint256 voteCount;
//         uint256 startTime;
//         uint256 endTime;
//         bool executed;
//     }

//     Proposal[] public proposals;
//     mapping(address=>mapping(uint=>bool)) public hasVoted;

//     function createProposal(string memory name,uint duration) public{
//         proposals.push(Proposal({
//             name:name,
//             voteCount:0,
//             startTime:block.timestamp,
//             endTime:block.timestamp+duration,
//             executed:false
//         }));
//     }

//     function vote(uint proposalId) public{
//         Proposal storage proposal=proposals[proposalId];
//         require(block.timestamp>=proposal.startTime,"Too early");
//         require(block.timestamp<=proposal.endTime,"Too late");
//         require(!hasVoted[msg.sender][proposalId],"Already voted");

//         hasVoted[msg.sender][proposalId]=true;
//         proposal.voteCount++;
//     }

//     function executeProposal(uint proposalId) public{
//         Proposal storage proposal=proposals[proposalId];
//         require(block.timestamp>proposal.endTime,"Too early");
//         require(!proposal.executed,"Already executed");

//         proposal.executed=true;
//     }



// }

// Gas Optimized version
contract GasEfficientVoting{
    // Use uint8 for small number instead of uint256
    uint8 public proposalCount;

    // Compact struct using minimal space types
    struct Proposal{
        bytes32 name;// Use bytes32 instead of string to save gas
        uint32 voteCount;// Supports up to ~4.3 billion votes
        uint32 startTime;
        uint32 endTime;
        bool executed;
    }

    // Using a mapping instead of an array for proposals is more gas efficient for access
    mapping(uint8=>Proposal) public proposals;// proposalId=> struct of proposal

    //     mapping(address=>mapping(uint8=>bool)) public voted;
    // Compress all of a voter's history into a single uint256:
    // - Each **bit** represents whether they voted on that proposal.
    // - Bit 0 = voted on Proposal 0
    // - Bit 1 = voted on Proposal 1
    // - …and so on, up to 256 proposals.
    // store all votes in one storage slot per address
    mapping(address=>uint256) private voterRegistry;

    mapping(uint8=>uint32) public proposalVoterCount;// Tracks how many voters voted for each proposal.

    event ProposalCreated(uint8 indexed proposalId,bytes32 name);
    event Voted(address indexed voter,uint8 indexed proposalId);
    event ProposalExecuted(uint8 indexed proposalId);

    function createProposal(bytes32 name,uint32 duration) external{
        require(duration>0,"Duration must be >0");
        
        // Mark the number of "proposalId".
        uint8 proposalId=proposalCount;
        proposalCount++;

        // It is cheaper to bulid data structures off-chian and then write them to storage only once.
        Proposal memory newProposal=Proposal({name:name,voteCount:0,startTime:uint32(block.timestamp),endTime:uint32(block.timestamp)+duration,executed:false});
        proposals[proposalId]=newProposal;
        emit ProposalCreated(proposalId,name);
    }

    function vote(uint8 proposalId) external{
        require(proposalId<proposalCount,"Invalid proposal");

        uint32 currentTime=uint32(block.timestamp);
        require(currentTime>=proposals[proposalId].startTime,"Voting not started");
        require(currentTime<=proposals[proposalId].endTime,"Voting ended");

        uint256 voterData=voterRegistry[msg.sender];
        // Check if already voted.
        // Use binary format to show which ID of proposal is voted.
        // "proposalId" shows the "1" position in the binary format.
        // 1 << proposalId creates a binary mask like 000100 (if proposalId is 2).
        uint256 mask= 1<<proposalId;
        // Here the variables coded in binary format is calculated bit by bit.
        // A,B,A & B
        // 0,0,  0
        // 0,1,  0
        // 1,0,  0
        // 1,1,  1
        require((voterData&mask)==0,"Already voted");

        // Record the proposalId which "msg.sender" has voted for in binary format.
        // Here the variables coded in binary format is calculated bit by bit.
        // A,B,A | B
        // 0,0,  0
        // 0,1,  1
        // 1,0,  1
        // 1,1,  1
        voterRegistry[msg.sender]=voterData|mask;

        proposals[proposalId].voteCount++;
        proposalVoterCount[proposalId]++;

        emit Voted(msg.sender,proposalId);
    }

    function executeProposal(uint8 proposalId) external{
        require(proposalId<proposalCount,"Invalid proposal");
        require(block.timestamp>proposals[proposalId].endTime,"Voting not ended");
        require(!proposals[proposalId].executed,"Already executed");

        proposals[proposalId].executed=true;

        emit ProposalExecuted(proposalId);

    }

    function hasVoted(address voter,uint8 proposalId) external view returns(bool){
        // Here the variables coded in binary format is calculated bit by bit.
        // A,B,A & B
        // 0,0,  0
        // 0,1,  0
        // 1,0,  0
        // 1,1,  1
        return (voterRegistry[voter]&(1<<proposalId)!=0);
    }

    function getProposal(uint8 proposalId) external view returns(bytes32 name,uint32 voteCount,uint32 startTime, uint32 endTime, bool executed,bool active){
        require(proposalId<proposalCount,"Invalid proposal");
        Proposal storage proposal=proposals[proposalId];
        return(proposal.name,proposal.voteCount,proposal.startTime,proposal.endTime,proposal.executed,(block.timestamp>=proposal.startTime&&block.timestamp<=proposal.endTime));
    }
       
    


}