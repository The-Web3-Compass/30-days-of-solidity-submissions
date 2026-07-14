//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract IOU_Contract{
    /*
    1. 定义owner，memeber，mapping balance， mapping bool, nested mapping debts
    2. constructor： owner，owner = friend
    3. modifier：owner/friend
    4. addfriends
    5. 存钱（权限认证，大于0）
    6. 记录欠债（权限认证，大于0，欠债人要是注册的，提供的欠债人地址合法）
    7. 还钱：
    */

    address owner;
    address[] friendList;
    mapping (address => bool) registeredFriend;
    mapping (address => uint256) balance;
    mapping (address => mapping(address => uint256)) debts; //nested mapping: debts[debtor][creditor] = amount


    constructor(){
        owner = msg.sender;
        registeredFriend[msg.sender] = true;
        friendList.push(msg.sender); 
    }

    modifier ownerOnly(){
        require (msg.sender == owner,"Only owner can perform this action.");
        _;
    }

    modifier registeredOnly(){
        require (!registeredFriend[msg.sender],"Only friends can perform this action.");
        _;
    }

    function addfriend(address _friend) public ownerOnly{
        require (_friend !=address(0),"Invalid address.");
        require (!registeredFriend[msg.sender], "Friend already registered.");

        registeredFriend[_friend] = true;
        friendList.push(_friend);
    }

    function depositIntoWallet() public payable registeredOnly{
        require (msg.value > 0, "must send ETH");
        balance[msg.sender] += msg.value;
    }

    function recordDebt(address _debtor, uint256 _amount) public registeredOnly {
        require(_debtor != address(0),"Invalid address");
        require(registeredFriend[_debtor],"Address not registered");
        require(_amount > 0, "Amount must be greater than 0");

        debts[_debtor][msg.sender] += _amount;
    }

    function payFromWallet(address _creditor, uint256 _amount) public registeredOnly{
        require(_creditor != address(0),"Invalid address");
        require(registeredFriend[_creditor], "Creditor not registered." );
        require(_amount >0, "Amount must be greater than 0");
        require(debts[msg.sender][_creditor] >= _amount, "Debt amount not correct.");
        require(balance[msg.sender] >= _amount,"Insufficient balance.");

        balance[msg.sender] -= _amount;
        balance[_creditor] += _amount;
        debts[msg.sender][_creditor] -= _amount;
        //address正确；address注册了；还钱数大于0；还钱的债务真实存在且amount正确；还钱的人余额有钱

    }

    function transferEther(address payable _to, uint256 _amount) public registeredOnly{
        require(_to !=address(0),"Invalid address");
        require(registeredFriend[_to],"Recipientnot registered"); 
        require(_amount > 0, "Invalid amount");
        require(balance[msg.sender] >= _amount,"Insufficient balance");

        balance[msg.sender] -= _amount;
        _to.transfer(_amount);  //recipientAddress.transfer(amount)
        balance[_to] += _amount;
    }
    //address payable:可以接受ETH的地址，可以用.transfer()銆�.send()銆�.call()进行转账

      // recipient.transfer(_amount) 发送失败会自动 revert（报错）;固定 gas 2300,只够目标地址收钱，不够执行复杂逻辑,如果你往一个合约地址转账，而对方合约有 fallback 函数（收钱后还有逻辑），transfer 会失败

      function transferEtherViaCall(address payable _to, uint256 _amount) public registeredOnly{
        require (_to !=address(0), "Invalid address");
        require (registeredFriend[_to], "Recipient not registered");
        require (_amount>0, "invalid amount");
        require (balance[msg.sender] >= _amount,"Insufficient balance");

        balance[msg.sender] -= _amount;

        (bool success, ) = _to.call{value: _amount}(""); //解释一下这句？详细的解释语法
        // (bool success, ) = recipient.call{value: amount}("");
        //这是一种 更灵活的转账方式，不会被 2300 gas 限制卡住; 但更容易被恶意合约攻击（重入攻击）
        balance[_to] += _amount;
        require(success, "Transfer failed");
      }

      function withdraw(uint256 _amount) public registeredOnly{
        require(balance[msg.sender] >= _amount, "Insufficient balance.");

        balance[msg.sender] -= _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require (success, "Withdrawal failed");
      }

      function checkBalance() public registeredOnly view returns (uint256){
        return balance[msg.sender];
      }
    }
