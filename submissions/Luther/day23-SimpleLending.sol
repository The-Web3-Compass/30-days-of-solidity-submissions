//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title SimpleLending
 * @dev A basic DeFi lending and borrowing platform
 */
contract SimpleLending {

    //将每个用户的地址映射到他们的存款余额
    mapping(address => uint256) public depositBalances;

    //记录每个用户的借款金额
    mapping(address => uint256) public borrowBalances;

    //记录每个用户存入的抵押品金额，抵押品是借款的前提条件
    mapping(address => uint256) public collateralBalances;

    //这是一个抵押因子，也以基点表示，用来决定用户可以借取多少资金
    // 500 基点 = 5% 利率
    uint256 public interestRateBasisPoints = 500;

    //这是一个抵押因子，也以基点表示，用来决定用户可以借取多少资金
    //决定可以用抵押品借到多少钱
    uint256 public collateralFactorBasisPoints = 7500;

    //记录每个用户上一次利息计算的时间戳
    //用于在计算利息时参考
    mapping(address => uint256) public lastInterestAccrualTimestamp;

    //声明一个 Deposit 事件，当用户存款时触发，记录存款用户和金额
    event Deposit(address indexed user, uint256 amount);
    //声明一个 Withdraw 事件，记录提取用户地址和提取金额
    event Withdraw(address indexed user, uint256 amount);
    //声明一个 Borrow 事件，记录借款用户和借款金额
    event Borrow(address indexed user, uint256 amount); 
    //声明一个 Repay 事件，记录还款用户和还款金额
    event Repay(address indexed user, uint256 amount);    
    //声明一个 CollateralDeposited 事件，记录用户存入抵押品的金额
    event CollateralDeposited(address indexed user, uint256 amount);     
    //声明一个 CollateralWithdrawn 事件，记录用户提取抵押品的金额
    event CollateralWithdrawn(address indexed user, uint256 amount);   

    //一个存款函数，允许用户将 ETH 存入智能合约
    function deposit() external payable {
        //如果存款金额为 0 或负数，合约会抛出错误，拒绝存款
        require(msg.value > 0, "Must deposit a positive amount");
        //更新存款余额，记录用户存入的资金
        depositBalances[msg.sender] += msg.value;
        //触发 Deposit 事件，记录存款的用户地址和存款金额
        emit Deposit(msg.sender, msg.value);
    }

    //声明一个 withdraw 函数，接受一个参数 amount，表示提款金额
    //允许用户从合约中提取资金
    function withdraw(uint256 amount) external {
        //如果提款金额为 0 或负数,则报错
        require(amount > 0, "Must withdraw a positive amount");
        //检查用户的存款余额是否大于等于提款金额
        require(depositBalances[msg.sender] >= amount, "Insufficient balance");
        //更新存款余额，将提款金额从用户的存款中扣除
        depositBalances[msg.sender] -= amount;
        //将指定的金额（amount）转账给用户
        payable(msg.sender).transfer(amount);
        //触发提款事件，记录提款用户和提款金额
        emit Withdraw(msg.sender, amount);
    }

    //声明一个 depositCollateral 函数，接受 ETH 存入作为抵押品
    //允许用户将ETH存入合约作为抵押品
    function depositCollateral() external payable {
        //检查存入的抵押品金额必须大于 0
        require(msg.value > 0, "Must deposit a positive amount as collateral");
        //将存入的抵押金额 msg.value 添加到用户的抵押品余额中
        collateralBalances[msg.sender] += msg.value;
        //触发 CollateralDeposited 事件，记录存入抵押品的用户地址和金额
        emit CollateralDeposited(msg.sender, msg.value);
    }

    //允许用户提取存入的抵押品，但会先进行一些检查，确保提取操作不会破坏合约的借贷规则
    function withdrawCollateral(uint256 amount) external {
        //在执行提取操作之前，确保用户提供的 amount 是一个有效的正数
        require(amount > 0, "Must withdraw a positive amount");
        //检查用户的抵押品余额是否足够提取指定数量的抵押品
        require(collateralBalances[msg.sender] >= amount, "Insufficient collateral");

        //该行代码用于获取用户的当前债务总额。通过调用 calculateInterestAccrued 函数，计算用户的借款余额（包括利息部分）
        uint256 borrowedAmount = calculateInterestAccrued(msg.sender);
        //计算用户必须保留的最低抵押品金额
        uint256 requiredCollateral = (borrowedAmount * 10000) / collateralFactorBasisPoints;

        //确保用户提取抵押品后，仍然符合借贷平台的抵押品比例要求
        require(
            collateralBalances[msg.sender] - amount >= requiredCollateral,
            "Withdrawal would break collateral ratio"
        );

        //减少用户的抵押品余额，表示用户提取了 amount 数量的抵押品
        collateralBalances[msg.sender] -= amount;
        //将指定数量的抵押品（以 ETH 形式）转账给用户
        payable(msg.sender).transfer(amount);
        //触发 CollateralWithdrawn 事件，记录抵押品提取操作
        emit CollateralWithdrawn(msg.sender, amount);
    }

    //这是借款功能，允许用户根据他们的抵押品借款一定金额
    function borrow(uint256 amount) external {
        //验证借款金额必须是正数
        require(amount > 0, "Must borrow a positive amount");
        //确保合约中有足够的资金池可供借款
        //address(this).balance 返回合约当前余额
        //require 检查合约是否有足够的资金来发放借款
        require(address(this).balance >= amount, "Not enough liquidity in the pool");

        //计算用户可以借款的最大金额，基于用户的抵押品和抵押因子
        //计算方式为用户的抵押品余额乘以抵押因子，除以 10000
        uint256 maxBorrowAmount = (collateralBalances[msg.sender] * collateralFactorBasisPoints) / 10000;
        //调用 calculateInterestAccrued 函数，获取用户当前的债务（包括本金和利息）。
        uint256 currentDebt = calculateInterestAccrued(msg.sender);

        //使用 require 检查当前债务加上借款金额是否超过了最大允许借款金额
        require(currentDebt + amount <= maxBorrowAmount, "Exceeds allowed borrow amount");

        //新用户的借款余额，将新的借款金额加到现有债务中
        borrowBalances[msg.sender] = currentDebt + amount;
        //更新用户的利息计算时间戳
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;

        //将借款金额 amount 转账给用户（借款人）
        payable(msg.sender).transfer(amount);
        //触发 Borrow 事件，记录借款用户和借款金额
        emit Borrow(msg.sender, amount);
    }

    //function repay() 声明还款函数
    //payable 允许函数接收 ETH
    //用户调用该函数偿还借款
    function repay() external payable {
        //验证还款金额必须为正
        require(msg.value > 0, "Must repay a positive amount");

        //获取用户当前需要偿还的债务金额
        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        //检查用户是否有未偿还的债务，如果没有，则抛出错误
        require(currentDebt > 0, "No debt to repay");

        //将还款金额 msg.value 设置为待偿还的金额
        uint256 amountToRepay = msg.value;
        //如果还款金额大于当前债务，则仅偿还剩余的债务，多余的部分退回用户
        if (amountToRepay > currentDebt) {
            //更新用户的借款余额，将已偿还的金额从债务中扣除
            amountToRepay = currentDebt;
            //更新利息结算时间，确保下次计算利息时从正确的时间开始
            payable(msg.sender).transfer(msg.value - currentDebt);
        }

        //更新用户的借款余额
        //用用户当前的债务总额 currentDebt 减去用户偿还的金额 amountToRepay，并将结果赋值回 borrowBalances[msg.sender]，更新用户的借款余额
        borrowBalances[msg.sender] = currentDebt - amountToRepay;
        //记录本次还款操作发生的时间
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;

        //触发 Repay 事件，记录用户的还款行为
        emit Repay(msg.sender, amountToRepay);
    }

    //计算并返回指定用户所欠的总债务，包括本金和利息
    function calculateInterestAccrued(address user) public view returns (uint256) {
        //如果用户没有借款（即借款余额为 0），则没有利息应付，返回 0
        if (borrowBalances[user] == 0) {
            return 0;
        }
        
        //block.timestamp 获取当前时间戳（自纪元以来的秒数）
        //lastInterestAccrualTimestamp[user] 是用户上次计算利息的时间戳
        //计算自上次利息结算以来已经经过的时间
        uint256 timeElapsed = block.timestamp - lastInterestAccrualTimestamp[user];
        //利息计算公式
        //根据借款余额、利率和时间差计算应付的利息
        uint256 interest = (borrowBalances[user] * interestRateBasisPoints * timeElapsed) / (10000 * 365 days);

        //返回计算后的借款总额，包括本金和利息
        return borrowBalances[user] + interest;
    }

    //声明一个外部视图函数 getMaxBorrowAmount，接受一个用户地址 user，并返回一个 uint256 类型的值
    //计算用户可以借款的最大额度，基于用户的抵押品和抵押因子
    function getMaxBorrowAmount(address user) external view returns (uint256) {
        //返回用户可以借款的最大金额
        //计算公式为：用户抵押品余额乘以抵押因子，再除以 10000 来转换基点
        return (collateralBalances[user] * collateralFactorBasisPoints) / 10000;
    }

    //声明一个外部视图函数 getTotalLiquidity，返回合约的总流动性，返回类型为 uint256
    //返回合约当前的流动资金池余额
    function getTotalLiquidity() external view returns (uint256) {
        //返回合约当前的资金池余额（即合约持有的所有 ETH 总额）
        return address(this).balance;
    }
}
