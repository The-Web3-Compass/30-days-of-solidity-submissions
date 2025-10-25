//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

// Use solidity to write on-chain group ledger. It can help people track debts, store ETH in their own in-app balance and settle up easily without doing math or spreadsheets.
contract SimpleIOU{
    address public owner;

    //Track registered friends
    mapping(address=>bool) public registeredFriends;
    address[] public friendList;

    //Track balances
    mapping(address=>uint256) public balances;

    //Simple debt tracking
    mapping(address=>mapping(address=>uint256)) public debts;// debtor->creditor->amount

    constructor(){
        owner=msg.sender;
        registeredFriends[msg.sender]=true;
        friendList.push(msg.sender);
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner can perform this action");
        _;
    }

    modifier onlyRegistered(){
        require(registeredFriends[msg.sender],"You are not registered");
        _;
    }

    //Register a new friend
    function addFriend(address _friend) public onlyOwner{
        require(_friend!=address(0),"Invalid address");
        require(!registeredFriends[_friend],"Friend already registered");

        registeredFriends[_friend]=true;
        friendList.push(_friend);
    }

    //Deposit funds to your balance
    function depositIntoWallet() public payable onlyRegistered{
        require(msg.value>0,"Must send ETH");
        balances[msg.sender]+=msg.value;
    }

    //Record that someone owes you money
    function recordDebt(address _debtor, uint256 _amount) public onlyRegistered{
        require(_debtor!=address(0),"Invalid address");
        require(registeredFriends[_debtor],"Address not registered");
        require(_amount>0,"Amount must be greater than 0");

        debts[_debtor][msg.sender]+=_amount;

    }

    //Pay off debt using internal balance transfer
    function payFromWallet(address _creditor, uint256 _amount) public onlyRegistered{
        require(_creditor!=address(0),"Invalid address");
        require(registeredFriends[_creditor],"Creditor not registered");
        require(_amount>0,"Amount must be greater than 0");
        require(debts[msg.sender][_creditor]>=_amount,"Debt amount incorrect");
        require(balances[msg.sender]>=_amount,"Insufficient balance");

        //Update balances and debt
        balances[msg.sender]-=_amount;
        balances[_creditor]+=_amount;
        debts[msg.sender][_creditor]-=_amount;
    }

    // Direct transfer method using transfer(
    function transferEther(address payable _to,uint256 _amount) public onlyRegistered{
        require(_to!=address(0),"Invalid address");
        require(registeredFriends[_to],"Recipient not registered");
        require(balances[msg.sender]>=_amount,"Insufficient balance");
        balances[msg.sender]-=_amount;

        //transfer() is a built-in Solidity method used to send ETH from a contract to an external address.
        //Syntax: recipientAddress.transfer(amount);
        //If using this syntax, the declaration of the address of recipient is "address payable" which means that address have ability like "transfer","send" and "call" for transactions. 
        // "address(this)" sends amounts to "_to"
        // When transfering amounts in contracts from account A to account B, generally not directly. First account A transfer amount to contract, and then contract transfer amount to account B. 
        _to.transfer(_amount);
        balances[_to]+=_amount;
    }

    // Alternative transfer method using call()
    function transferEtherViaCall(address payable _to,uint256 _amount) public onlyRegistered{
        require(_to!= address(0),"Invalid address");
        require(registeredFriends[_to],"Recipient not registered");
        require(balances[msg.sender]>=_amount,"Insufficient balance");

        balances[msg.sender]-=_amount;

        // Sending ETH using "call()".
        // call() is a low-level function in Solidity used for sending ETH and calling functions. 
        // Syntax: (bool success, ) = recipient.call{value: amount}("");
        //If using `call()`, it’s up to you to: check whether it succeeded,handle any failure cases properly and make sure the contract is protected from reentrancy attacks (more on that later in advanced contracts)
        // "address(this)" sends amounts to "_to"
        // When transfering amounts in contracts from account A to account B, generally not directly. First account A transfer amount to contract, and then contract transfer amount to account B. 
        (bool success,)=_to.call{value:_amount}("");
        balances[_to]+=_amount;
        require(success,"Transfer failed");
    }

    // Withdraw your balance
    function withdraw(uint256 _amount) public onlyRegistered{
        require(balances[msg.sender]>=_amount,"Insufficient balance");
        balances[msg.sender]-=_amount;
        // Only the address have declaration of "payable" can call.
        // "address(this)" sends amounts to "msg.sender"
        // When transfering amounts in contracts from account A to account B, generally not directly. First account A transfer amount to contract, and then contract transfer amount to account B. 
        (bool success,)=payable(msg.sender).call{value:_amount}("");
        require(success,"Withdrawal failed");
    }

    //Check your balance
    function checkBalance() public view onlyRegistered returns(uint256){
        return balances[msg.sender];
    }
}