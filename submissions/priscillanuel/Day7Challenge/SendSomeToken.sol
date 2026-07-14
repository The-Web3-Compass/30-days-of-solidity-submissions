// SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

 

contract SendSomeTokens is ReentrancyGuard {

    address public owner;// the owner of the contract
    mapping (address =>bool) registereFriends;// registered Friends
    address[] public friendList; // an array list of the registered friends
    mapping (address =>uint256) public balances; // balances of the friends
    mapping(address => mapping(address => uint256)) public debts;

 // ---------------- CONSTRUCTOR ------------------------------- 

 constructor () {
    owner = msg.sender; //makes the deployer of the contract the owner
    registereFriends[msg.sender] = true;
    friendList.push(msg.sender);
 }
 // ---------------- MODIFIER------------------------------- 
 modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can call this function");
    _;
  }

  modifier onlyRegisteredFriends() {
    require(registereFriends[msg.sender], "Only registered friends can call this function");
    _;
  }

  function addFriends ( address _friendAddress ) onlyOwner public {
    require (registereFriends[msg.sender] == true, "only resigisteres friends can call");
    require(_friendAddress != msg.sender, "You can't add yourself as a friend");
    require(_friendAddress != address(0), "the adress must not ve empty");

    registereFriends[_friendAddress] = true;
    friendList.push(_friendAddress);
  }

  function depositIntoWallet () public payable onlyRegisteredFriends {
    require(msg.value > 0, "You must send some eth");
    balances[msg.sender] += msg.value;
    
  }

  function recordDebt(address _debtor, uint256 _amount) public onlyRegisteredFriends {
    require (_debtor != address(0), "debtor address must not be empty");
    require( _amount > 0,"you can't put zero debt");
    require(registereFriends[_debtor], "address not registered");

    debts[_debtor][msg.sender] += _amount;
    updatedDebts[_debtor][msg.sender] = block.timestamp;
  } 

  function payFromWallet(address _creditor, uint _amount) public onlyRegisteredFriends {
    require (_creditor != address(0), "creditor address must not be empty");
    require(_amount > 0, "you can't pay zero amount");
    require(registereFriends[_creditor], "creditor not registered");
    require(debts[msg.sender][_creditor] >= _amount, "debt amount incorrect");
    require(balances[msg.sender] >= _amount,"you dont have enough balance" );

    balances[msg.sender] -= _amount;
    balances[_creditor] += _amount;
    debts[msg.sender][_creditor] -= _amount;

  }

  function tranferEther(address payable  _to, uint _amount) public onlyRegisteredFriends nonReentrant {
    require(_to != address(0), "you can't send to zero address");
    require(_amount > 0, "you cannot send zero ether");
    require(registereFriends[_to], "you are not registered");
    require(balances[msg.sender] >= _amount, "you dont have enough balance");

    balances[msg.sender] -= _amount;

    (bool success, ) = _to.call{value: _amount}("");
    balances[_to] += _amount;
    require(success, "Transfer failed");
    }
    
    function withdraw(uint _amount) public onlyRegisteredFriends nonReentrant {
        require (_amount > 0, "you cannot withdraw zero ether");
        require (balances[msg.sender ]>= _amount, "you dont have enough balance");

        balances[msg.sender] -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    function checkBalance() public view onlyRegisteredFriends returns (uint) {
        return balances[msg.sender ];
    }

    // ----------------INTEREST-RATES----------------
    uint public interestRate = 5; // interest rate of 5% on overdue
    uint public overdue = 5 minutes; // the time an debts starts to increase
    mapping(address => mapping(address => uint256)) public updatedDebts;


    
    function overDueInterest(address _debtor)public onlyRegisteredFriends {
    require(registereFriends[_debtor], "address not registered");

    uint256 debt = debts[_debtor][msg.sender];
    require(debt > 0, "no debt");

    uint256 lastTime = updatedDebts[_debtor][msg.sender];
    uint256 timeElapsed = block.timestamp - lastTime;

    require(timeElapsed > overdue, "not overdue yet");

    // only count time AFTER overdue period
    uint256 overdueDuration = timeElapsed - overdue;

    // normalize time (yearly interest)
    uint256 interest = (debt * interestRate * overdueDuration)
        / (100 * 365 days);

    debts[_debtor][msg.sender] += interest;
    updatedDebts[_debtor][msg.sender] += interest;

    // reset timer so it can't be abused
    updatedDebts[_debtor][msg.sender] = block.timestamp;
}

function debtForgiveness(address _debtor) public onlyRegisteredFriends {
  require (_debtor != address(0), "address vot Zero");
  require (_debtor != msg.sender, "You can't forgive yourself");
  require (debts[_debtor][msg.sender] > 0, "You don't owe anything to this person");
  require (registereFriends[_debtor],"you must forgive only people in the list");

  uint amount = debts[_debtor][msg.sender];
  uint forgiveDebts = amount * 0;
  debts[_debtor][msg.sender] -= forgiveDebts;
}
}