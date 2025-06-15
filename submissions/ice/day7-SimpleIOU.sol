// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SimpleIOU
 * @notice 支持点对点借贷、还款、额度设置、记录查询的合约。所有资金单位为 wei。
 */
contract SimpleIOU {
    struct DebtRecord {
        address counterparty; // 对方地址（借出人或借入人）
        uint256 amount;       // 当前债务金额
        bool isLender;        // 如果当前账户是出借人，则为 true
        bool isRepaid;        // 债务是否已还清
    }

    mapping(address => uint256) private balances;              // 用户余额
    mapping(address => uint256) private borrowLimit;           // 用户设置的可被借额度
    mapping(address => DebtRecord[]) private debts;            // 用户债务记录

    event Deposit(address indexed user, uint256 amount);
    event SetBorrowLimit(address indexed user, uint256 limit);
    event Borrow(address indexed borrower, address indexed lender, uint256 amount);
    event Repay(address indexed borrower, address indexed lender, uint256 amount);

    /**
     * @notice 存入 ETH，仅能由调用者自身发起
     * @dev msg.value 会直接累加至调用者余额，要求存款金额大于 0
     * 示例：用户 A 调用 deposit() 并发送 1 ether
     */
    function deposit() external payable {
        require(msg.value > 0, "Must deposit more than 0");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice 查询调用者自身余额
     * @return 当前账户 ETH 余额（单位为 wei）
     * 示例：用户 A 调用 getMyBalance() → 返回账户余额
     */
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    /**
     * @notice 设置或更新允许被借的上限，仅限自身操作
     * @dev 限制不得超过当前余额
     * 示例：用户 A 调用 setBorrowLimit(0.5 ether)
     */
    function setBorrowLimit(uint256 limit) external {
        require(limit <= balances[msg.sender], "Limit cannot exceed balance");
        borrowLimit[msg.sender] = limit;
        emit SetBorrowLimit(msg.sender, limit);
    }

    /**
     * @notice 公开查询任意用户设置的借款额度
     * @param user 用户地址
     * @return 用户允许借出的最大额度（单位为 wei）
     * 示例：调用 getUserBorrowLimit(0x123...)
     */
    function getUserBorrowLimit(address user) external view returns (uint256) {
        return borrowLimit[user];
    }

    /**
     * @notice 查询调用者的债务记录，可过滤角色与偿还状态
     * @param filterByLender 是否启用角色过滤
     * @param lenderValue 角色过滤值 true:出借人 false:借款人
     * @param filterByRepaid 是否启用偿还状态过滤
     * @param repaidValue 偿还状态过滤值 true:已还清 false:未还清
     * @return 满足条件的债务记录数组
     * 示例：getMyDebts(true, false, true, false) → 查询我作为借款人、仍未还清的记录
     */
    function getMyDebts(bool filterByLender, bool lenderValue, bool filterByRepaid, bool repaidValue) external view returns (DebtRecord[] memory) {
        DebtRecord[] memory all = debts[msg.sender];
        uint256 count = 0;

        for (uint256 i = 0; i < all.length; i++) {
            if ((!filterByLender || all[i].isLender == lenderValue) &&
                (!filterByRepaid || all[i].isRepaid == repaidValue)) {
                count++;
            }
        }

        DebtRecord[] memory filtered = new DebtRecord[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < all.length; i++) {
            if ((!filterByLender || all[i].isLender == lenderValue) &&
                (!filterByRepaid || all[i].isRepaid == repaidValue)) {
                filtered[j++] = all[i];
            }
        }
        return filtered;
    }

    /**
     * @notice 向他人借款，仅能自己调用
     * @param lender 出借人地址
     * @param amount 借款金额（单位为 wei）
     * @dev 不可借给自己；不能超过对方设置的额度和余额；不能向欠自己钱的人借款
     * 示例：borrow(0xLender, 0.1 ether)
     */
    function borrow(address lender, uint256 amount) external {
        require(lender != msg.sender, "Cannot borrow from self");
        require(amount > 0, "Amount must be greater than zero");
        require(borrowLimit[lender] >= amount, "Exceeds lender's borrow limit");
        require(balances[lender] >= amount, "Lender has insufficient balance");

        DebtRecord[] memory records = debts[msg.sender];
        for (uint256 i = 0; i < records.length; i++) {
            require(!(records[i].counterparty == lender && !records[i].isRepaid && !records[i].isLender), "You already owe this person");
        }

        balances[lender] -= amount;
        balances[msg.sender] += amount;
        borrowLimit[lender] -= amount;

        debts[msg.sender].push(DebtRecord({
            counterparty: lender,
            amount: amount,
            isLender: false,
            isRepaid: false
        }));
        debts[lender].push(DebtRecord({
            counterparty: msg.sender,
            amount: amount,
            isLender: true,
            isRepaid: false
        }));

        emit Borrow(msg.sender, lender, amount);
    }

    /**
     * @notice 向指定出借人偿还借款，仅能自己调用
     * @param lender 债主地址
     * @param amount 偿还金额（单位为 wei）
     * @dev 支持部分偿还，金额不能超过原始欠款；若金额归零则视为已还清
     * 示例：repay(0xLender, 0.05 ether)
     */
    function repay(address lender, uint256 amount) external {
        require(amount > 0, "Must repay more than 0");

        DebtRecord[] storage borrowerRecords = debts[msg.sender];
        DebtRecord[] storage lenderRecords = debts[lender];

        bool found = false;

        for (uint256 i = 0; i < borrowerRecords.length; i++) {
            if (borrowerRecords[i].counterparty == lender && !borrowerRecords[i].isLender && !borrowerRecords[i].isRepaid) {
                require(amount <= borrowerRecords[i].amount, "Repay amount exceeds debt");
                require(balances[msg.sender] >= amount, "Insufficient balance to repay");

                balances[msg.sender] -= amount;
                balances[lender] += amount;

                borrowerRecords[i].amount -= amount;

                for (uint256 j = 0; j < lenderRecords.length; j++) {
                    if (lenderRecords[j].counterparty == msg.sender && lenderRecords[j].isLender && !lenderRecords[j].isRepaid) {
                        lenderRecords[j].amount -= amount;

                        if (borrowerRecords[i].amount == 0) {
                            borrowerRecords[i].isRepaid = true;
                            lenderRecords[j].isRepaid = true;
                        }
                        break;
                    }
                }

                found = true;
                break;
            }
        }

        require(found, "No active debt to this address");
        emit Repay(msg.sender, lender, amount);
    }

    /**
     * === 调试示例输入说明 ===
     * 1. 存款：调用 deposit() 并附带 ETH，如 1 ether
     * 2. 查询余额：调用 getMyBalance() → 返回账户余额
     * 3. 设置额度：调用 setBorrowLimit(0.5 ether) 设置允许被借上限
     * 4. 查询他人额度：调用 getUserBorrowLimit(0xABC...)
     * 5. 借款：调用 borrow(0xABC..., 0.2 ether) 向对方借 0.2 ETH
     * 6. 查询记录：getMyDebts(true, false, true, false) → 查看我作为借款人未还清的记录
     * 7. 还款：调用 repay(0xABC..., 0.1 ether) 偿还部分欠款
     */
}
