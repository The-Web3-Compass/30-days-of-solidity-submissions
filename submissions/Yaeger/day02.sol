//SPDX-License-Identifier:MIT
contract Savemyname{
    string name;
    string bio;
    function add (string memory _name,string memory_bio)public{
        name =_name;
        bio =_bio;
    }
    function retrieve() public view (string memory,string memory ){
        return(name,bio);

    }

    
}
