//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0;

contract SimpleIOU{
     address public Owner;
     address [] FriendList;
     mapping (address => bool) public RegisteredFriends;
     mapping (address => uint256) public balances;
     mapping (address => mapping(address => uint256)) public debts;

     constructor(){
        Owner = msg.sender;
        RegisteredFriends[msg.sender] = true;
        FriendList.push(msg.sender);

     }

     modifier OnlyOwner(){
        require (msg.sender == Owner, "Only the owner can call this function");
        _;

     }

     modifier OnlyRegistered(){
        require (RegisteredFriends[msg.sender], "You are not registered");
        _;

     }

     function AddFriend(address _friend_) public OnlyOwner{
        require(_friend_ != address(0), "Invalid address");
        require(!RegisteredFriends[_friend_], "Already added as a friend");
        RegisteredFriends[_friend_] = true;
        FriendList.push(_friend_);

     }

     function DepositIntoWallet() public payable OnlyRegistered{
        require(msg.value > 0, "Must enter a valid amount");
        balances[msg.sender] += msg.value;

     }

     function RecordDebt(address _debter_, uint256 _amount_) public OnlyRegistered{
        require(_debter_ != address(0), "Invalid address");
        require(RegisteredFriends[_debter_], "Address is not registered");
        require(_amount_ > 0, "Must enter a valid amount");
        debts[_debter_][msg.sender] += _amount_;

     }

     function PayFromWallet(address _creditor_, uint256 _amount_) public OnlyRegistered{
        require(_creditor_ != address(0), "Invalid address");
        require(RegisteredFriends[_creditor_], "Creditor not registered");
        require(_amount_ > 0, "Amount must be greater than 0");
        require(debts[_creditor_][msg.sender] >= _amount_, "Debt amount is incorrect");
        require(balances[msg.sender] >= _amount_, "Insufficient balance");
        balances[msg.sender] -= _amount_;
        balances[_creditor_] += _amount_;
        debts[_creditor_][msg.sender] -= _amount_;

     }

     function TransferEther(address payable _to_,uint256 _amount_) public OnlyRegistered{
        require(_to_ != address(0), "Invalid address");
        require(RegisteredFriends[_to_], "Reciepient not registered");
        require(balances[msg.sender] >= _amount_, "Insufficient balance");
        balances[msg.sender] -= _amount_;
        _to_.transfer(_amount_);
        balances[_to_] +=_amount_;

     }

     function TransferEtherViaCall(address payable _to_,uint256 _amount_) public OnlyRegistered{
        require(_to_ != address(0), "Invalid address");
        require(RegisteredFriends[_to_], "Reciepient not registered");
        require(balances[msg.sender] >= _amount_, "Insufficient balance");
        balances[msg.sender] -= _amount_;
        (bool success,) = _to_.call{value:_amount_}("");
        balances[_to_] +=_amount_;
        require(success, "Failed to transfer Ether");

     }

     function Withdraw(uint256 _amount_) public OnlyRegistered{
        require(balances[msg.sender] >= _amount_, "Insufficient balance");
        balances[msg.sender] -= _amount_;
        (bool success,) = payable (msg.sender).call{value: _amount_}("");
        require(success, "Failed to withdraw");

     }

     function CheckBalance() public view OnlyRegistered returns(uint256){
        return balances[msg.sender];

     }


}

