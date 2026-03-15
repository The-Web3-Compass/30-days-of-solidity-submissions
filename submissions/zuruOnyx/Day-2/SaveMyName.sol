// SPDX-License-Identifier:MIT
pragma solidity ^0.8.23;


contract SaveMyName {
    struct Profile {
        string firstName;
        string surname;
        string bio;
        string userName;
    }

    error BIO_TOO_LONG();
    error CANT_PASS_AN_EMPTY_STRING();


    mapping(address => Profile) details;

    function concatenate(string memory a, string memory b) public pure returns (string memory) {
    return string(abi.encodePacked(a, b));
}

    function addDetails(string memory _firstname, string memory _surname, string memory _bio) public {
        if(bytes(_firstname).length == 0 || bytes(_surname).length == 0 || bytes(_bio).length == 0){
            revert CANT_PASS_AN_EMPTY_STRING();
        }
        
        if(bytes(_bio).length > 32){
            revert BIO_TOO_LONG();
        }    

        details[msg.sender].firstName = _firstname;
        details[msg.sender].surname = _surname;
        details[msg.sender].bio = _bio;
        details[msg.sender].userName = concatenate(_firstname, _surname);  

    }

    function getDetails()external view returns(Profile memory){
        return details[msg.sender];
    }

    function editDetails(string memory _firstname, string memory _surname, string memory _bio)external {
      if(bytes(_firstname).length == 0 || bytes(_surname).length == 0 || bytes(_bio).length == 0){
            revert CANT_PASS_AN_EMPTY_STRING();
        }
        
        if(bytes(_bio).length > 32){
            revert BIO_TOO_LONG();
        }

     

        details[msg.sender].firstName = _firstname;
        details[msg.sender].surname = _surname;
        details[msg.sender].bio = _bio;
        details[msg.sender].userName = concatenate(_firstname, _surname);

    }

}
