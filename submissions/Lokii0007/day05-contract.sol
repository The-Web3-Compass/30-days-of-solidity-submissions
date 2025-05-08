// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract AdminOnly {
    address public owner;
    uint256 treasureAmount;
    mapping(address => uint256) withdrawlAllowance;
    mapping(address => bool) hasWithdrawn;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "AdminOnly: unathorized");
        _;
    }

    function addTreasure(uint _amount) public onlyOwner {
        treasureAmount += _amount;
    }

    function approveWithdrawls(
        address recipient,
        uint256 _amount
    ) public onlyOwner {
        require(
            _amount <= treasureAmount,
            "withdrawl amount must be less than treasure amount"
        );
        withdrawlAllowance[recipient] = _amount;
    }

    function withdrawTreasure(uint256 _amount) public {
        require(_amount <= treasureAmount);
        if (msg.sender == owner) {
            treasureAmount -= _amount;
            return;
        }

        require(
            withdrawlAllowance[msg.sender] > 0,
            "withdrawl amount must be less than treasure amount"
        );
        require(
            withdrawlAllowance[msg.sender] >= _amount,
            "withdrawl amount must be less than treasure amount"
        );
        require(hasWithdrawn[msg.sender] == false, "already withdrawn");
        treasureAmount -= _amount;
        withdrawlAllowance[msg.sender] -= _amount;
        hasWithdrawn[msg.sender] = true;
    }

    function resetWithdrawStatus(address _user) public onlyOwner {
        hasWithdrawn[_user] = true;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    function getTreasureDetails() public view onlyOwner returns(uint256){
        return treasureAmount;
    }

}
