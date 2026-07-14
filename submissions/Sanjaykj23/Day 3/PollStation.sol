pragma solidity ^0.8.10;
contract Vote{
    uint[] private  candidate_uid=[0,1,2,3,4,5];
    uint[] votes=[0,0,0,0,0,0];
    mapping(address=>uint)to_vote;
    mapping (address=>bool)is_voted;
    function vote(uint n)public {
        require(n>=0 && n<6,"Invalid ID");
        require(is_voted[msg.sender]==false,"Already Voted");
        to_vote[msg.sender]=n;
        is_voted[msg.sender]=true;
        votes[n]++;
    }
    function getVote(uint n)public view returns(uint){
        require(n>=0 && n<6,"Invalid ID");
        return votes[n];
    }
    function Winner()public view returns (uint ){
        uint t=0;
        uint cnt=votes[0];
        for(uint i=0;i<=5;i++){
            if(cnt<votes[i]){
                cnt=votes[i];
                t=i;
            }
        }
        return t;
    }
}