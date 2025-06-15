//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract AdminOnly{

    address public Owner;
    uint256 public TreasureAmount;
    mapping (address => uint256) public WithdrawalAllowance;
    mapping (address => bool) HasWithdrawn;

    constructor(){
        Owner = msg.sender;

    }

    modifier OnlyOwner(){
        require(msg.sender == Owner, "Access denied: Only the owner can perform this action");
        _;
    }

    function AddTreasure(uint256 amount) public OnlyOwner{

        //require(msg.sender == Owner, "Access denied: Only the owner can perform this action");

        //if this condition passes continue to function logic,
        TreasureAmount += amount; 
    }

    function ApproveWithdrawal(address recipient, uint256 amount) public OnlyOwner{
        require(amount <=TreasureAmount, "Insufficient funds in the contract");
        WithdrawalAllowance[recipient] = amount;

    }

    function WithdrawTreasure(uint256 amount) public {
        if(msg.sender == Owner){
            require(amount <= TreasureAmount, "Insufficient funds in the contract");
            TreasureAmount-= amount;
            return;
        }

        uint256 Allowance = WithdrawalAllowance[msg.sender];

        require(Allowance > 0, "You do not have any treasure allowance");
        require(!HasWithdrawn[msg.sender], "You have already withdrawan your treasure");
        require(Allowance <= TreasureAmount, "Not enough treasure in the chest");
        require(amount <= Allowance, "Not enough allowance for withdrawl");

        HasWithdrawn[msg.sender] = true;
        TreasureAmount -= amount;
        WithdrawalAllowance[msg.sender] = 0;

    }

    function ResetWithdrawalStatus(address User) public OnlyOwner{
        HasWithdrawn[User] = false;

    }

    function TransferOwnership(address NewOwner) public OnlyOwner{
        require(NewOwner != address(0), "Invalid new owner");
        Owner = NewOwner;

    }

    function GetTreasureDetails() public view OnlyOwner returns(uint256){
        return TreasureAmount;

    }


}
