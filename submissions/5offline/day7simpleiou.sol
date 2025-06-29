//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;
//谁欠谁钱的合同

contract simpleiou{
    //声明变量：owner，注册朋友，朋友列表，账户和欠的金额

    address public owner;
    mapping(address=>bool)public registeredfriends;
    address[]public friendlist;
    mapping(address=>uint256)public balances;
    mapping(address=>mapping(address=>uint256)) public debts;
    //嵌套mapping

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
        //添加用户
    }
    function depositintowallet()public payable onlyRegistered{
        require(msg.value>0,"must enter eth amount.");
        balances[msg.sender] +=msg.value;
        //存款，需要用到payable，真的存款

    }

    function recorddebt(address _debtor,uint256 _amount) public onlyRegistered{
        require(_debtor !=address(0),"invalid address");
        require(registeredfriends[_debtor],"address is not registered");
        require(_amount>0, "must enter a valid amount.");
        debts[_debtor][msg.sender] +=_amount;}
        //记录欠债，负债的那个人，金额/debt[a][b] a欠b多少钱 


        function payfromwallet(address _creditor, uint256 _amount)public onlyRegistered{
             require(_creditor !=address(0),"invalid address");
        require(registeredfriends[_creditor],"address is already registered");
        require(_amount>0, "amount must be greater than 0");
        //这部分为止和上面一样
        require(debts[msg.sender][_creditor]>= _amount,"debt amount incorrect.");
        require(balances[msg.sender]>=_amount,"insuffcient payment.");
        //从自己的钱包里出钱，要看钱包的里的余额
        balances[msg.sender]-=_amount;
        balances[_creditor]+=_amount;
        //两边账户变动
         debts[msg.sender] [_creditor]-=_amount;


        }
        function transfereth(address payable _to,uint256 _amount) public onlyRegistered{
            require(_to !=address(0),"invalid address");
        require(registeredfriends[_to],"address is already registered");
        //以太币转账，虽然address写了payable但是没有msg.value
         //address payable _to，这只是表明：_to 这个地址可以接收以太币。
         //transfer是合约账户余额 -> 收款人，不需要msg.value
         //msg.value是把外面的钱拿过来给合约

        require(balances[msg.sender]>=_amount,"insuffcient payment.");
        balances[msg.sender]-=_amount;
        _to.transfer(_amount);//这一步调用了solidity里面的转账函数
       
        }

        function transferEtherViaCall(address payable _to,uint256 _amount)public onlyRegistered{
            require(_to !=address(0),"invalid address");
        require(registeredfriends[_to],"address is already registered");
        require(balances[msg.sender]>=_amount,"insuffcient payment.");
        //这部分为止和上面一样
        balances[msg.sender]-=_amount;
        (bool success,) =_to.call{value: _amount}("");
        //后面还会用到：call xx金额用.call的方式转给_to这个账户
       balances[_to]+=_amount;
       require(success, "tranfer failed.");
       //要给反馈

        }

        function withdraw(uint256 _amount)public onlyRegistered{
            require(balances[msg.sender]>=_amount,"insuffcient payment.");
            //取款
        balances[msg.sender]-=_amount;
         (bool success,) = payable(msg.sender).call{value: _amount}("");
         //把xx金额的钱从合约转到可以接受以太币的msg.sender账户
         require(success, "withdrawal failed.");

        }
        function checkbalance() public view onlyRegistered returns(uint256){

            return balances [msg.sender];}

    }



// mapping(address=>mapping(address=>uint256)) public debts;嵌套mapping，按顺序看
//debt[a][b] a欠b多少钱 同理debts[msg.sender][_creditor]和 debts[_debtor][msg.sender]并不一样，一个是欠钱，一个是被欠钱
//balance是账户，debt是欠债总额，amount是这次还多少
//call:底层调入函数，不受到2300gas限制，=_to.call{value: _amount}("");
//其中表示给_to丢进去_amount金额的钱（“”）这个一般是对应合约的时候实才用，可以调用里面的函数
//payable(msg.sender) 变成可以转入的钱包地址
//function functionName(parameters) visibility modifiers returns (...) 
    // 函数体









