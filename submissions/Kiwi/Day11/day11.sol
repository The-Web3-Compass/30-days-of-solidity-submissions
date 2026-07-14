//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

contract Ownerable{
    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {

        owner = msg.sender;
        emit OwnershipTransferred(address(0),msg.sender);

    }

    modifier Owner() {
        require(msg.sender == owner,"Only owner can perform this action");
        _;
    }

    function ownerAddress() public view returns(address) {
        return owner;
    }

    function transferOwnership(address _newOwner) public Owner{
        require(_newOwner !=address(0),"Invalid address");
        address previous = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previous,_newOwner);

    }

}
