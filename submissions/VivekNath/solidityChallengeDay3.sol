// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;



contract pollStation {

 error Person__Minor(); //Create an custom error if age in < 18 year voter is minor
 error Already__Voted(); // A single address can vote only once
 error Invalid__Name(); // check the name is invalid or empty string

struct Candidate {
    string name;
    uint256 VoteCount;
}
Candidate[] public  candidates;


mapping(address => bool) public hasVote; //Map the  address who can vote 
mapping(address => uint) public favouriteCandidate; //Map the address which candidate to vote



function addCandidate(string memory _name , uint256 _age) public {
if(_age < 18){
    revert Person__Minor();
}
if(bytes(_name).length == 0){ //candidate name can not be empty
    revert Invalid__Name();
}


candidates.push(Candidate(_name,0)); // After all checks we can push the Candidate name and the vote count is 0 

}



function Vote(uint256 _index, uint256 _age) public {
    if(_age < 18){
        revert Person__Minor();
    }
if(hasVote[msg.sender]){ //Only a single address can only vote once
    revert Already__Voted();
}
   

    hasVote[msg.sender] = true; //Checks the sender has voted
    favouriteCandidate[msg.sender] = _index; // Record which candidate the sender voted for

    candidates[_index].VoteCount++; //Increment the vote count for voted candidate
}

function totalCandidate() public view returns(uint256){
    return candidates.length;
}

function retriveCandidate(uint256 _index) public view returns(string memory , uint256){
    Candidate storage getCandidate = candidates[_index]; //candidate is reference to the storage 
    return(getCandidate.name,getCandidate.VoteCount);
}




}
