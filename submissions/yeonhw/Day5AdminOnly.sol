// SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

contract AdminOnly{
    address public owner;

    constructor(){
        owner = msg.sender;  //存储部署合约的人的地址 甲方 只执行一次！
    }
    //msg.sender 是 当前调用这个合约函数的地址
    //部署合约时：msg.sender 是部署者地址
    //调用函数时：msg.sender 是谁点击按钮发起了调用

    modifier onlyOwner(){  //可重用权限检查，检查调查方是否为所有者，如果不是，函数则不会运行
        require(msg.sender == owner, "Access denied: Only the owner can perform this action.");
        _; //检查通过时插入函数其余部分的位置？
    }

    uint256 public treasureAmount;

    function addTreasure(uint256 amount) public onlyOwner{ //只有owner可以调用该函数 onlyOwner修饰符确保没有随机的人可以偷偷溜进来添加或假装添加宝藏
        treasureAmount += amount;
    }
    //？？deploy时发现treasure初始值是100，这个可以更改初始值吗？

    mapping(address => uint256) public withdrawalAllowance;  //使用map来跟踪每个地址允许提取的金额
    //需要事先设定哪些非owner的地址可以提取宝藏？

    function approveWithdrawal(address recipient, uint256 amount) public onlyOwner{ //owner想允许某人取出宝藏 
        require(amount <= treasureAmount, "Not enough treasure available"); //需要先检查宝箱中是否有足够的钱
        withdrawalAllowance[recipient] = amount;
    }

    mapping(address => bool) public hasWithdrawn; //判断是否已经提取出 但是如果还有剩呢？
    //这个映射是如何设定的bool值变化的依据是什么？需要设定吗？后面在提取完成后设定为0
    
    //withdraw撤回.退出     withdrawal取款
    function withdrawTreasure(uint256 amount) public{  //提取的时候会发生的情况拆解
        if(msg.sender == owner){  //所有者提款
            require(amount <= treasureAmount,"Not enough treasury available for this action."); //需要有足够的钱
            treasureAmount -= amount;
            return;  //return的作用是提前退出函数
        }

        //如果非所有者想要提款
        uint256 allowance = withdrawalAllowance[msg.sender];
        require(allowance > 0, "You don't have any treasure allowance"); //要求得到批准
        require(!hasWithdrawn[msg.sender],"You have already withdrawn your treasure"); //宝藏还没被他取走
        require(allowance <= treasureAmount, "Not enough treasure in the chest");//宝藏里的数量够吗？

        //完成提款
        hasWithdrawn[msg.sender] = true; //标记已提取
        treasureAmount -= allowance; //从宝箱中减去被取走的数量
        withdrawalAllowance[msg.sender] = 0; //提取完成后将bool值设为0，保证非owner一个人只能取一次宝藏
    }

    function resetWithdrawalStatus(address user)public onlyOwner{
        hasWithdrawn[user] = false; //owner输入想要重置提款次数的人的地址，可以使他获得再次提款的次数
    }

    function transferOwnership(address newOwner) public onlyOwner{ //转让所有权
        require(newOwner != address(0), "Invalid address"); //确保新地址不为空
        owner = newOwner;
    }

    function getTreasureDetails() public view onlyOwner returns(uint256){ //查看宝藏
        return treasureAmount;
    }

}
