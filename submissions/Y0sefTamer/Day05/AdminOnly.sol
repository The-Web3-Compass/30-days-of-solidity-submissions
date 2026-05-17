// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


contract AdminOnly {
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public  withdrawalAllowance;
    mapping(address => bool) public  hasWithdrawn;
    mapping(address => uint256) public  maximumWithdrawal; 

    event TreasureAdded(address indexed admin, uint256 amount);
    event TreasureWithdrawn(address indexed recipient, uint256 amount);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event WithdrawalApproved(address indexed recipient, uint256 amount);
    event MaximumWithdrawalSet(address indexed recipient, uint256 amount);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }


     modifier onlyOwner() {
       require(msg.sender == owner, "Access denied: Only the owner can perform this action");
       _;
     }

    function addTreasure() public payable  onlyOwner {
        treasureAmount += msg.value;
        emit TreasureAdded(msg.sender, msg.value);
    }

    function setWithdrawalAllowance(address _user, uint256 _amount, uint256 _maximumWithdrawal) public onlyOwner {
        require(_amount <= treasureAmount, "Not enough treasure available");
        withdrawalAllowance[_user] = _amount;
        maximumWithdrawal[_user] = _maximumWithdrawal;
        emit WithdrawalApproved(_user, _amount);
        emit MaximumWithdrawalSet(_user, _maximumWithdrawal);
    }

    function withdraw(uint256 amount) public   {
        uint256 amountToWithdraw;

       if (msg.sender == owner) {
         require(amount <= treasureAmount, "Not enough treasury available");
         amountToWithdraw = amount;
         treasureAmount -= amount;
       }else {
            
            uint256 allowance = withdrawalAllowance[msg.sender];
            require(allowance > 0, "No allowance");
            require(!hasWithdrawn[msg.sender], "Already withdrawn");
            require(amount <= allowance, "Exceeds allowance");
            require(amount <= treasureAmount, "Contract empty");
            require(amount <= maximumWithdrawal[msg.sender], "Exceeds maximum withdrawal");

            amountToWithdraw = amount;
            hasWithdrawn[msg.sender] = true;
            treasureAmount -= amount;
            withdrawalAllowance[msg.sender] -= amount;
       }

       (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Transfer failed");

        emit TreasureWithdrawn(msg.sender, amountToWithdraw);
    }

    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawn[user] = false;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        
    }
    
    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function checkMyStatus(address user) public view returns (uint256 allowance, bool withdrawn) {
        return (withdrawalAllowance[user], hasWithdrawn[user]);
    }
    
   
}



