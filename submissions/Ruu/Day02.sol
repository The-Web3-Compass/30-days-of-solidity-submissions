//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0;

contract SaveMyName {

    string name;
    string bio;

    function add(string memory _name_, string memory _bio_) public {
        name = _name_;
        bio = _bio_;
    }
    
    function retrieve() public view returns (string memory, string memory){
        return(name, bio);
    }

    function SaveAndRetrieve(string memory _name_, string memory _bio_) public returns(string memory, string memory){
        name = _name_;
        bio = _bio_;
        return (name, bio);
    }

}
