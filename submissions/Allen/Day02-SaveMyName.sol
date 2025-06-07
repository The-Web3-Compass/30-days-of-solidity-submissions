// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SaveMyName{

    string name;
    string bio;

    function add(string memory _name,string memory _bio) public {
        require(bytes(_name).length != 0,"please enter again");
        require(bytes(_bio).length != 0,"please enter again");
        name = _name;
        bio = _bio;
    }

    function retrieve()  public view returns(string memory ,string memory ){
        return (name,bio);
    }

    // More Efficient,But it's costs more gas
    function saveAndRetrieve(string memory _name,string memory _bio) public
     returns(string memory ,string memory ){
        require(bytes(_name).length != 0,"please enter again");
        require(bytes(_bio).length != 0,"please enter again");
        name = _name;
        bio = _bio;
        return (name,bio);
    }

}