//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;
//这个合同指的是只有管理者才能从国库？公款？提款之类的，和钱有关的东西


contract adminonly{
    address public owner;
    uint256 public treasureamount;
    mapping(address=>uint256) public withdrawalallowance;
    //外人有多少额度可以提取
    mapping(address=>bool) hasWithdrawn;
//声明变量：owner，公款账户，外人提取额度，提了没有
    constructor(){
        owner=msg.sender;

    }
    modifier onlyowner(){
        require (msg.sender==owner,"access denied: only the owner can perform this action.");
        _;
    }
    //第一次接触modifier，他在合同前半部分声明，能用到的话就在public后面加onlyowner，不符合这个修正符的就会被踢出去
    //=是赋值，==是验证
    function addtreasure(uint256 amount)public onlyowner{
        treasureamount+=amount;
    }
    //指在原有的treasureamount上加amount，等于新的 treasureamount
    function approvewithdraw(address recipient, uint256 amount)public onlyowner{
        require(amount<=treasureamount,"insuffcient funds in the contract");
        withdrawalallowance[recipient]=amount;
    }
    //提取最高额度就=输入的amount
    function withdrawtreasure(uint256 amount)public {
       if (msg.sender==owner){
        require(amount<=treasureamount,"insufficient funds in the contract. ");
        treasureamount -=amount;
        return;
       }
       //owner提取的过程，不是owner就往下走
       uint256 allowance=withdrawalallowance[msg.sender];
       require (allowance>0,"You don't have any treasure allowance.");
       require(!hasWithdrawn[msg.sender],"you have already withdrawn your treasure.");
       require(allowance<=treasureamount, "not enough treasure in the chest.");
       require(amount<=allowance, "not enough allowance for withdrawal.");
       //赋值让allowance和上面的那个批准的数额相等，然后看amount，和他们之间数字的对比


       hasWithdrawn[msg.sender]=true;
       treasureamount-=allowance;
       withdrawalallowance[msg.sender]=0;
       //结束了这一切之后，标记取款，然后从国库里减allowance的数字，不管提多少都以最高额减
    }
    function resetwithdrawalstatus(address user)public onlyowner{
        hasWithdrawn[user]=false;
        }
        //重置让这个人再提取一次
        function transferownership(address newowner)public onlyowner{


            require(newowner != address(0),"invalid new owner");
            owner=newowner;

        }
        //换一个最高执行人
        function gettreasuredetails()public view onlyowner returns(uint256){

            return(treasureamount);
        }
        //最后得到amount详情

}


