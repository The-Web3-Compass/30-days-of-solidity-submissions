// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly{

    // 当前宝藏拥有者 （合约提交者）
    address private owner;
    // 宝藏总额度
    uint private totalAmount;
    // 每个地址允许提取数量的映射
    mapping(address=>uint) private withdrawalMap;
    // 每个地址是否已经提取
    mapping(address=>bool) private deawalBoolMap;

    //构造函数，初始化宝藏拥有者为发布合约者
    constructor() {
        owner = msg.sender;
    }

    /* modifier 函数修饰符，相当于提取的公共代码，在function前后执行， _; 代表function方法体的执行
       function中可以声明多个modifier，按照声明顺序执行
       _; 一般是要写的，如果不写，修饰的function代码就会不执行
    
        require 第一个参数是判断条件，
        true时继续执行下面的代码
        false时，抛出异常，中断当前方法执行，回退前面执行的所有代码，修改的链上数值倒回（包括本方法修改的数据和调用其他合约修改的数据），已消费的gas费用不予退回，剩余gas费用退回
        返回第二个参数作为提示语，提示语必须是纯ASCII字符（数字、英文、符号等），不能包含中文
        如果要写中文：  unicode"不是宝藏拥有者"  这样写
    */
    modifier ownerOnly(){
        require(owner == msg.sender, unicode"不是宝藏拥有者");
        _;
    }

    //添加宝藏额度
    function setTotalAmount(uint _totalAmount) public ownerOnly{
        totalAmount += _totalAmount;
    }

    /*
    宝藏拥有者身份移交
    
    修饰方法时，modifier 有请求参数时，参数声明在请求function参数列表中，modifier只写参数名
    modifier参数有三种情况
    无参数
    常数，修饰方法时直接写固定值
    变量，声明在function参数列表
    */ 
    function changeOwner(address newOwner,uint c) public ownerOnly chack( c){
        require(newOwner != address(0),unicode"不允许转换给零地址");
        owner = newOwner;
    }

    modifier chack(uint c){
        _;
    }
     //查询宝藏余额
     function getTotalAmount() public view ownerOnly returns(uint)  {
        return  totalAmount;
     }
     //获取宝藏
     function withdrawTreasure(uint amount) public {
        //管理员直接提取
        if(owner == msg.sender){
            require(amount <= totalAmount,unicode"提取数量超过了宝藏余额");
            totalAmount -= amount;
            return ;
        }
        // 非管理员提取
        require(withdrawalMap[msg.sender] > 0 ,unicode"该客户未分配额度，不可以提取宝藏");
        require(!deawalBoolMap[msg.sender],unicode"该客户已经提取过宝藏，不可重复提取");
        require(amount <= totalAmount,unicode"提取数量超过了宝藏余额");
        require(amount <= withdrawalMap[msg.sender],unicode"提取额度超过了分配额度");

        totalAmount -= amount;
        withdrawalMap[msg.sender] -= amount;
        deawalBoolMap[msg.sender] = true;
     }

     //给某客户分配宝藏额度
     function setWithdrawal(address custAddress,uint amount) public ownerOnly {
        withdrawalMap[custAddress] = amount;
     }



}