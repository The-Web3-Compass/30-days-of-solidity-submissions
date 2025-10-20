// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract SimpleLending{
    // 记录用户存款余额
    mapping(address => uint256) public depositBalances;
    // 记录用户借款本金
    mapping(address => uint256) public borrowBalances;
    // 记录用户抵押的ETH数量
    mapping(address => uint256) public collateralBalances;
    
    // Interest rate in basis points (1/100 of a percent)
    // 500 basis points = 5% interest
    uint256 public interestRateBasisPoints = 500;
    // Collateral factor in basis points (e.g., 7500 = 75%)
    // Determines how much you can borrow against your collateral
    uint256 public collateralFactorBasisPoints = 7500;
    // Timestamp of last interest accrual
    mapping(address => uint256) public lastInterestAccrualTimestamp;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    
    // 存款 把ETH存进银行
    function deposit() external payable{
        require(msg.value > 0, "please deposit a positive amount.");
        depositBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    // 取款 从银行取钱
    function withdraw(uint256 amount) external{
        require(amount > 0, "please withdraw a positive amount.");
        require(depositBalances[msg.sender] > amount, "insufficient balance.");
        depositBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    // 抵押
    function depositCollateral() external payable {
        require(msg.value > 0, "Must deposit a positive amount as collateral");
        collateralBalances[msg.sender] += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }
    
    // 取回抵押的ETH
    function withdrawCollateral(uint256 amount) external {
        
        require(amount > 0, "Must withdraw a positive amount");
        // 检查你抵押的ETH够不够取
        require(collateralBalances[msg.sender] >= amount, "Insufficient collateral");
        // 计算你当前的总负债（本金+利息）
        uint256 borrowedAmount = calculateInterestAccrued(msg.sender);
        
        // 计算你还需要留多少抵押物才能保证贷款安全
        // requiredCollateral = 借款总额 / 抵押率
        uint256 requiredCollateral = (borrowedAmount * 10000) / collateralFactorBasisPoints;
        
        // 检查取出后剩下的抵押物是否还足够
        require(
            collateralBalances[msg.sender] - amount >= requiredCollateral,
            "Withdrawal would break collateral ratio"
        );
        
        // 更新抵押余额
        collateralBalances[msg.sender] -= amount;
        // 把ETH转回用户
        payable(msg.sender).transfer(amount);

        emit CollateralWithdrawn(msg.sender, amount);

    }
    
    // 借出
    function borrow(uint256 amount) external {
        
        require(amount > 0, "Must borrow a positive amount");
        // 检查合约池子里有没有足够的ETH可借
        require(address(this).balance >= amount, "Not enough liquidity in the pool");
        
        // 计算你最多能借多少（抵押物 * 抵押率）
        uint256 maxBorrowAmount = (collateralBalances[msg.sender] * collateralFactorBasisPoints) / 10000;
        
        // 计算你当前的总负债（本金+利息）
        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        
        // 检查借完后是否超过最大可借额度
        require(currentDebt + amount <= maxBorrowAmount, "Exceeds allowed borrow amount");
        
        // 更新你的借款余额（加上新借的）
        borrowBalances[msg.sender] = currentDebt + amount;
        
        // 更新上次计息时间戳
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;
        
        // 把ETH转给你
        payable(msg.sender).transfer(amount);
        emit Borrow(msg.sender, amount);
    
    }

    // 还款
    function repay() external payable {
        require(msg.value > 0, "Must repay a positive amount");
        // 计算你当前总负债（本金+利息）
        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        require(currentDebt > 0, "No debt to repay");
        // 记录你实际想还的金额
        uint256 amountToRepay = msg.value;
        
        // 如果你多还了，自动退回多余部分
        if (amountToRepay > currentDebt) {
            amountToRepay = currentDebt;
            payable(msg.sender).transfer(msg.value - currentDebt);
        }
        
        // 更新你的借款余额
        borrowBalances[msg.sender] = currentDebt - amountToRepay;
        // 更新上次计息时间戳
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;
        emit Repay(msg.sender, amountToRepay);
    }

    // 动态计算用户当前应还的总债务（本金+利息）
    // 利息 = 本金 × 年利率 × 时间（秒） / （10000 × 365天）
    function calculateInterestAccrued(address user) public view returns (uint256) {
        if (borrowBalances[user] == 0) {
            return 0;
        }
        // 计算距离上次结息经过了多少秒
        uint256 timeElapsed = block.timestamp - lastInterestAccrualTimestamp[user];
        // 365 days == 31,536,000 秒
        uint256 interest = (borrowBalances[user] * interestRateBasisPoints * timeElapsed) / (10000 * 365 days);

        return borrowBalances[user] + interest;
    }
    

    // 查询用户最大可借额度
    function getMaxBorrowAmount(address user) external view returns (uint256) {
        return (collateralBalances[user] * collateralFactorBasisPoints) / 10000;
    }
    // 返回合约当前ETH余额
    function getTotalLiquidity() external view returns (uint256) {
        return address(this).balance;
    }


}