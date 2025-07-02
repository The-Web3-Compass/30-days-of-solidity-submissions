//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

//import "./ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//@openzeppelin 部分是 Remix（以及许多 Solidity 项目）中使用的简写
//去取一个文件夹，contracts/access/Ownable.sol = 该包中的实际文件夹和文件路径

contract VaultMaster is Ownable{
    //在 VaultMaster 里 不用重新写 owner、onlyOwner、transferOwnership 的逻辑。
    //is 继承的是关键词，现在VaultMaster = Ownable + VaultMaster 自己的代码
    //简单的存款提款查看余额功能，具有所有权的简单 ETH 金库

    constructor() Ownable(msg.sender) {}

    //openzepplin要求声明这个constructor的初始位置
    event DepositSuccessful(address indexed account, uint256 value);
    event WithdrawSuccessful(address indexed recipient, uint256 value);
    //两个事件，记录存款和取款
    function deposit()public payable{
        require(msg.value>0, "invalide amount.");
        emit  DepositSuccessful(msg.sender, msg.value);
        //deposit(uint256 _ amount)不用写（）里面的东西，因为这里用的msg.value可以记录给了多少钱
        //return 是函数内部机制，emit 是链上日志，完全两回事。emit是把数据存起来了，return是返回调用方
        //当你要记录每个用户的余额、积分、或扩展业务逻辑时。balance[msg.sender]这个才需要计算，只看合约账单不用写balance式子

    }
    function  getBalance()public view returns (uint256){
        return address(this).balance;
    }
    //独立写完！且正确 虽然只有两行

    function withdraw(address _to,uint256 _amount ) public onlyOwner{
        //这里没说账户要是payable的

        require (_amount>0,"invalid amout.");
        require (_amount<= getBalance(), "Insufficient balance.");
        //对于转账金额的限制
        (bool success,) =payable(_to).call {value: _amount}("");
        require (success, "Transfer failed.");
        //转账的动作
        emit WithdrawSuccessful(_to , _amount);
        //记录在event
    }

    //在现实世界中，大多数开发人员不会从头开始编写所有内容。他们依赖于可信的库
    //在线下的共学营是从这个时刻开始学的：OpenZeppelin







}

