// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract etherPiggyBank{

    address bankManager;

    mapping (address => uint) balances;
    address[] members;
    mapping(address => bool) public registeredMembers;
    mapping(address => uint) lastWithdrawal;
    mapping (address => uint) dailyWithdrawn;
    // mapping (address => uint) weeklyWithdrawn;
    mapping(address => uint) public depositTime;
    uint constant DAILY_LIMIT = 1 ether;
    // uint constant WEEKLY_LIMIT = 7 ether;
    uint  groupGoal;
    uint  lockedUntil; // timestamp when funds unlock



    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    
    constructor(){
        bankManager = msg.sender;
        members.push(msg.sender);
        
    }

    modifier onlyBankManager{
        require(msg.sender == bankManager, "Only bank manager can call this function");
        _;
    }

    modifier onlyRegisteredMembers{
        require(registeredMembers[msg.sender], "Only registered members can call this function");
        _;
    }

    function addMembers(address _member) public onlyBankManager {
        require(_member != address(0), "Invalid address");
        require(_member != msg.sender, "Bank Manager is already a member");
        require(!registeredMembers[_member], "Member already registered");

        registeredMembers[_member] = true;
        members.push(_member);
    }

    function getmembers() external view returns (address[] memory){
        return members;
    }

    function setGroupGoal(uint _goal, uint lockDuration) external onlyBankManager {
    groupGoal = _goal;
    lockedUntil = block.timestamp + lockDuration;
    }

    function deposit() external payable onlyRegisteredMembers{
        require(msg.value > 0, "Not a valid value for payment");

        uint oldDeposit = balances[msg.sender];
        if(oldDeposit > 0 && depositTime[msg.sender] != 0){
             uint duration = block.timestamp - depositTime[msg.sender];
             uint interest = (oldDeposit * duration * 5) / (100 * 365 days); // 5% APR
             balances[msg.sender] += interest;
        }
        balances[msg.sender] += msg.value;
        depositTime[msg.sender] = block.timestamp;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) external onlyRegisteredMembers {
        require(amount > 0, "Invalid withdraw amount");    
        require(block.timestamp >= lockedUntil, "Funds are locked for group goal");

         if(block.timestamp - lastWithdrawal[msg.sender] >= 1 days){
            dailyWithdrawn[msg.sender] = 0;
         }

        require(dailyWithdrawn[msg.sender] + amount <= DAILY_LIMIT, "Withdrawal exceeded");

        // if(block.timestamp - lastWithdrawal[msg.sender] >= 7 days){
        //     weeklyWithdrawn[msg.sender] = 0;
        // }

        // require(weeklyWithdrawn[msg.sender] + amount <= WEEKLY_LIMIT, "Withdrawal exceeded");
 
        require(balances[msg.sender] >= amount, "Not enough balance");
        balances[msg.sender] -= amount;
        lastWithdrawal[msg.sender] = block.timestamp;
        dailyWithdrawn[msg.sender] += amount;
        // weeklyWithdrawn[msg.sender] += amount;


        (bool success, ) = payable (msg.sender).call{value: amount}("");
        require(success, "Failed to send Ether");
        emit Withdraw(msg.sender, amount);
    }
    
    function emergencyWithdraw(uint amount) external onlyRegisteredMembers {
    require(balances[msg.sender] >= amount, "Not enough balance");

    uint penalty = (amount * 10) / 100; // 10% penalty
    uint withdrawAmount = amount - penalty;

    balances[msg.sender] -= amount;

    (bool success, ) = payable(msg.sender).call{value: withdrawAmount}("");
    require(success, "Transfer failed");

    emit Withdraw(msg.sender, withdrawAmount);
}

    function getContractBalance() external view returns(uint){
    return address(this).balance;
   }


}