pragma solidity ^0.8.10;
contract AchivementsPlugin{
    mapping(address=>bytes32)LatestAchivements;
    struct Achivements{
        uint32 time;
        bytes32[] allAchivementsSoFar;
    }
    mapping(address=>Achivements)UserAchivements;
    function addAchivement(address user,bytes32 achivement)external{
        require(user!=address(0),"Wrong Address");
        LatestAchivements[user]=achivement;
        Achivements storage uAchivement=UserAchivements[user];
        if(uAchivement.time==0)uAchivement.time=uint32(block.timestamp);
        uAchivement.allAchivementsSoFar.push(achivement);
    }
    function getAchivement(address user)external returns(Achivements memory){
        require(user!=address(0),"Wrong Address");
        return UserAchivements[user];
    }
}