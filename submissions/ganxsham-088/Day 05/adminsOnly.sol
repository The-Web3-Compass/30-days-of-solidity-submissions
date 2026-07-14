pragma solidity  ^0.8.0;
 contract AdminOnly {
    address public owner;
    uint public treasureAmount;

    mapping(address => bool) public hasWithdrawn;
    mapping(address => uint256) public allowances;
    // mapping(address => bool) public isApproved;

    modifier onlyOwner(){
        require(msg.sender == owner, "Not the owner!");
        _;
    }
    constructor (){
        owner = msg.sender; 
    }
    function addTreasure(uint _amount) external onlyOwner{
        treasureAmount += _amount;
    }
    function approveWithdrawal(address _user, uint256 _amount) external onlyOwner{
        allowances[_user] = _amount;
    }
    function withdrawTreasure(uint256 _withrawal) external {
        require(allowances[msg.sender] > 0, "No allowance for you!");
        require(!hasWithdrawn[msg.sender], "You've already withdrawn!");
        uint _amountAllowed = allowances[msg.sender];
        require(treasureAmount >= _amountAllowed, "Not enough treasure!");
        require(_withrawal <= _amountAllowed, "Withdrawal exceeds allowance");
        treasureAmount -= _withrawal;
        allowances[msg.sender]-= _withrawal;
        hasWithdrawn[msg.sender] = true;
    }


    function transferOwnerShip ( address _newOwner) external onlyOwner{
        require(_newOwner != address(0), "Invalid address" );
        owner = _newOwner;
    }

    function resetWithrawl(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }

    function getAllowance(address _user) external view returns (uint256) {
        return allowances[_user];
    }

    function getTreasureAmount() external view returns (uint) {
        return treasureAmount;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getHasWithdrawn(address _user) external view returns (bool) {
        return hasWithdrawn[_user];
    }
 }