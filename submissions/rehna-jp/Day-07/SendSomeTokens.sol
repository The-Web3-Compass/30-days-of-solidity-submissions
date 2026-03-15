// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
  

contract sendTokens{
      
      address public owner;
      address[] friendList;
      mapping(address => bool) isRegistered;
      mapping (address => uint) balance;
      mapping(address => mapping(address => uint)) debts;

      constructor(){
           owner = msg.sender;
           isRegistered[msg.sender] = true;
           friendList.push(msg.sender);
      }

      modifier onlyOwner{
            require(msg.sender == owner, "You are not the owner");
            _;
      }

      modifier  onlyRegisteredFriends{
            require(isRegistered[msg.sender], "You are not a registered friend");
            _;
      }

      event Deposit(address indexed user, uint amount);
      event Payment(address indexed from, address indexed to, uint amount);
      event Withdrawal(address indexed user, uint amount);


      receive() external payable { 
              require(isRegistered[msg.sender], "You are not a registered friend");
              balance[msg.sender] += msg.value;
              emit Deposit(msg.sender, msg.value);
      }

      function addFriend(address friend) external onlyOwner{
            require(friend != address(0), "Invalid address");
            require(!isRegistered[friend], "Friend already registered");

            isRegistered[friend] = true;
            friendList.push(friend);

      }

      function deposit() external payable onlyRegisteredFriends{
            require(msg.value > 0, "Invalid amount");

            balance[msg.sender] += msg.value;
            emit Deposit(msg.sender, msg.value);
      }

      function addDebtor(address debtor, uint amount) external onlyRegisteredFriends{
           require(isRegistered[debtor], "Debtor is not registered");
           require(debtor != address(0), "Not a valid address");
           require(amount > 0, "Not a valid amount");

           debts[debtor][msg.sender] += amount;
      }



      function sendPayment(address payable reciever, uint amount) external  onlyRegisteredFriends{
         require(amount <= balance[msg.sender], "You do not have enough eth to send");
         require(amount > 0, "Not a valid amount");
         require(reciever != address(0), "Not a valid address");
         require(isRegistered[reciever], "Reciever is not registered");

         balance[msg.sender] -= amount;
         (bool success, ) = reciever.call{value: amount}("");
         balance[reciever] += amount;
         require(success, "transfer failed");

         emit Payment(msg.sender, reciever, amount);
        
      }

      function withdraw(uint amount) external  onlyRegisteredFriends{
            require(amount <= balance[msg.sender], "You do not have enough eth to withdraw");

            balance[msg.sender] -= amount;
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed");
 
            emit Withdrawal(msg.sender, amount);
      }

      function checkBalance() external view returns (uint) {
            return balance[msg.sender];
      }

      function getFriends() external view returns(address[] memory){
            return friendList;
      }
}