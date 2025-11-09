// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;
string name;
string bio;
contract savemyname{
function add(string memory _name, string memory _bio)public{
    name=_name;
    bio=_bio;


}
retrieve()public view returns(string memory,string memory){
    returns(name,bio);
}





}
