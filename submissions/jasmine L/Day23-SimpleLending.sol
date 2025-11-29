// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleLending{
    mapping (address => uint256) public depositBalances; //用户存入的ETH 可存可取
    mapping (address => uint256) public borrowBalances; //借贷账目 
    mapping (address => uint256) public collateralBalances; //抵押物品，保护系统，如果还不上钱就收回？
    // 怎么样收回呢？？？如果用户账户上没钱，这个抵押资产的收取资金的方式在哪里？
    /* 只有用户自己决定借贷之后，别人才可以借贷账户上的钱，否则万一人家想提钱，岂不是提不出来账户上没钱怎么办？
    * 解决办法是 因为抵押资金由多余，所以别人提取自己的钱总是有足够资金的
    */
    mapping (address => uint256) public lastInterestAccrualTimestamp; 
    // 利息如果频繁计算的话，则消耗gas得不偿失，记录每个用户上次计算利息的时间，每当用户触发新的行为，检查经过的时间计算利息
    // 避免使用浮点数计算
    uint256 public interestRateBasispoints = 500; // 年化利率500基点，1基点是0.01%，所以利息是5%
    uint256 public collateralFactorsBasisPoints = 7500; // 用户只能借如作为抵押资产的ETH 的75%
    
    // 一些广播事件
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed  user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed  user, uint256 amount);//还款啦！
    event CollateralDeposited(address indexed  user, uint256 amount);//锁定抵押品
    event CollateralWithdraw(address indexed user, uint256 amount);// 全权提取抵押品

     function deposit() external payable {
        require(msg.value > 0, "Not zero!");

        depositBalances[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
     }

    function withdraw(uint256 amount)external {
        require(amount > 0 , "illeagal number");
        require(depositBalances[msg.sender]>=amount, "Insufficient balance");

        depositBalances[msg.sender] -= amount;
        payable (msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }
    // 利息计算
    function calculateInterestAccrued(address user) public view returns(uint256){
        if(borrowBalances[user] == 0){
            return 0;
        }

        uint256 timeElapsed = block.timestamp - lastInterestAccrualTimestamp[user];
        uint256 interest = (borrowBalances[user] * interestRateBasispoints * timeElapsed)/(1000 * 365 days);
        return borrowBalances[user] + interest;
    }
    // 锁定抵押物品金额，暂时由本人在外部抵押之后将金额输送到ETH里面来
    // 如果这个时候账户没那么多钱怎么办
    function depositCollateral() external payable{
        require(msg.value > 0, "Not zero");

        collateralBalances[msg.sender] += msg.value;
        
        emit CollateralDeposited(msg.sender, msg.value);
    }
    //当自己的贷款金额没有风险的时候可以提取一部分金额 75%
    function withdrawCollateral(uint256 amount) external{
        require(amount > 0, "Not zero");
        require(collateralBalances[msg.sender] >= amount, "Insufficient collateral");//首先得有那么多钱

        uint256 borrowedAount = calculateInterestAccrued(msg.sender);
        uint256 requiredColleateral = (borrowedAount * 10000) / collateralFactorsBasisPoints;//有多少钱呗当成抵押锁定了

        require(collateralBalances[msg.sender] - amount >= requiredColleateral, "Insufficient balance to collateral");

        collateralBalances[msg.sender] -= amount;
        payable (msg.sender).transfer(amount);//提现

        emit CollateralWithdraw(msg.sender, amount);

    }
    //借钱，得有足够的抵押资金才可以借贷
    function borrow(uint256 amount) external{
        require(amount > 0, "Not zero");
        require(address(this).balance >= amount, "Not enough ETH in Contract");
        //其实有一个问题就是：如果他自己已经抵押了足够多的钱，那他借不超过75%，确实账户里面有钱呀
            // 可能是为了节省下面两句的gas费...
        //计算其可借款金额
        uint256 maxBorrowAmount = (collateralBalances[msg.sender]*collateralFactorsBasisPoints)/10000;
        //其已经欠款和债务呢，计算出了一共能借多少，期间他还可能再抵押，所以只需要计算总的欠款即可
        uint256 currentDebt = calculateInterestAccrued(msg.sender);

        require(currentDebt + amount <= maxBorrowAmount, "Insufficient Collateral to borrow");

        borrowBalances[msg.sender] += amount;

        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;
        //直到再次借贷才计算一部分利息
        // 这个利息的计算只要不继续借贷他的本金就没有变....
        payable (msg.sender).transfer(amount);
        emit Borrow(msg.sender, amount);
    }

    function repay() external payable{
        // 还钱多了得退
        // 只有彻底还清钱才能退还押金（其实可以提取押金的？）自己提取还是自动提取呢？(是否有个提取公式线下计算一下再提取呢？)
        // 什么时候还不起钱，那个抵押品金额归谁呢？

        require(msg.value>0, "Not zero");

        uint256  currentDebt = calculateInterestAccrued(msg.sender);//计算现今为止该还多少钱
        //如果还够了，是不是就可以提取抵押金了呢？涉及一些现实的资产和现实货币的汇率暂时就不考虑了
        require(currentDebt > 0, "No debt to repay");

        uint256 amountToRepay = msg.value;
        if(amountToRepay > currentDebt){
            amountToRepay = currentDebt;
            payable (msg.sender).transfer(msg.value - currentDebt);//返还多余的钱
        }

        borrowBalances[msg.sender] = currentDebt - amountToRepay;//这个时候计算的也是把利息本金一起算新的本金在一起了，所以还钱还是一次性还划算
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;

        emit Repay(msg.sender, amountToRepay);

    }
    // 一些查询函数
    // 查一下自己的抵押金还能借贷多少钱
    function getMaxBorrowAmount(address user) external view returns(uint256){
        return (collateralBalances[user]*collateralFactorsBasisPoints)/10000;
    }

    //查一下借贷池有多少可以借贷
    function getTotalLiquidity() external view returns (uint256){
        return address(this).balance;
    }
     
}
