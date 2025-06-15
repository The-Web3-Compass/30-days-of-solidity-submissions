//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

contract simpleiou{
    address public owner;
    mapping(address=>bool)public registeredfriends;
    address[]public friendlist;
    mapping(address=>uint256)public balances;
    mapping(address=>mapping(address=>uint256)) public debts;

    constructor(){
        owner=msg.sender;
        registeredfriends[msg.sender]=true;
        friendlist.push(msg.sender);

    }
    modifier onlyowner(){
        require(msg.sender==owner, "only owner can perform this action.");
        _;
    }

    modifier onlyRegistered() {
    require(registeredfriends[msg.sender], "You are not registered");
    _;
    }

    function addfriends(address _friend)public onlyowner{
        require(_friend != address(0),"invalid adderess.");
        require(!registeredfriends[_friend],"Friend already registered");
        registeredfriends[_friend]=true;
        friendlist.push(_friend);
    }
    function depositintowallet()public payable onlyRegistered{
        require(msg.value>0,"must enter eth amount.");
        balances[msg.sender] +=msg.value;


    }
    function recorddebt(address _debtor,uint256 _amount) public onlyRegistered{
        require(_debtor !=address(0),"invalid address");
        require(registeredfriends[_debtor],"address is not registered");
        require(_amount>0, "must enter a valid amount.");
        debts[_debtor][msg.sender] +=_amount;}


        function payfromwallet(address _creditor, uint256 _amount)public onlyRegistered{
             require(_creditor !=address(0),"invalid address");
        require(registeredfriends[_creditor],"address is already registered");
        require(_amount>0, "amount must be greater than 0");
        require(debts[msg.sender][_creditor]>= _amount,"debt amount incorrect.");
        require(balances[msg.sender]>=_amount,"insuffcient payment.");
        balances[msg.sender]-=_amount;
        balances[_creditor]+=_amount;
         debts[msg.sender] [_creditor]-=_amount;


        }
        function transfereth(address payable _to,uint256 _amount) public onlyRegistered{
            require(_to !=address(0),"invalid address");
        require(registeredfriends[_to],"address is already registered");
        require(balances[msg.sender]>=_amount,"insuffcient payment.");
        balances[msg.sender]-=_amount;
        _to.transfer(_amount);
    

        }

        function transferEtherViaCall(address payable _to,uint256 _amount)public onlyRegistered{
            require(_to !=address(0),"invalid address");
        require(registeredfriends[_to],"address is already registered");
        require(balances[msg.sender]>=_amount,"insuffcient payment.");
        balances[msg.sender]-=_amount;
        (bool success,) =_to.call{value: _amount}("");
       balances[msg.sender]-=_amount;
       require(success, "tranfer failed.");

        }

        function withdraw(uint256 _amount)public onlyRegistered{
            require(balances[msg.sender]>=_amount,"insuffcient payment.");
        balances[msg.sender]-=_amount;
         (bool success,) = payable(msg.sender).call{value: _amount}("");
         require(success, "withdrawal failed.");

        }
        function checkbalance() public view onlyRegistered returns(uint256){

            return balances [msg.sender];}

    }
    