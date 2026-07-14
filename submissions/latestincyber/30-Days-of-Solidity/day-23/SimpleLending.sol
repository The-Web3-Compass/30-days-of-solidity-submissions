// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//adding this to protect against a new vulnerability found from EIP-7702
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SimpleLending is ReentrancyGuard {
    mapping(address => uint256) public depositBalances;
    mapping(address => uint256) public borrowBalances;
    mapping(address => uint256) public collateralBalances;
    uint256 public interestRateBasisPoints = 500; // 5% interest
    uint256 public collateralFactorBasisPoints = 7500; // 75% LTV (loan to value)
    // real world LTV ratios: aave (50-80% depending on asset), compound (50-70% depending on asset),
    // makerDAO (150% you need $150 collateral for $100 loan)
    mapping(address => uint256) public lastInterestAccrualTimestamp; // interest compounds over time 
    // we need to know when the last calculation happened.

    function deposit() external payable {
        depositBalances[msg.sender] += msg.value;
    }

    function depositCollateral() external payable {
        collateralBalances[msg.sender] += msg.value;
    }

    function getCollateralValue(address user) public view returns (uint256) {
        return collateralBalances[user];
    }
    function getDebtValue(address user) public view returns (uint256) {
        return calculateInterestAccrued(user);
    }

    // add the modifiers to borrow, liquidate and flashLoan (part of defence from EIP7702 vuln)
    function borrow(uint256 amount) external nonReentrant { ...}
    function liquidate(address borrower) external payable nonReentrant { ... }
    function flashLoan(uint256 amount) external nonReentrant { ... }

    // interest = principal * rate * time
    // we use basis points because solidity doesn't have decimals (so we use intergers)
    // instead of 5% as 0.05 (impossible) we store 500 and divide by 10000
    function calculateInterestAccrued(address user) public view returns (uint256) {
        if (borrowBalances[user] == 0) return 0; 
        uint256 timeElapsed = block.timestamp - lastInterestAccrualTimestamp[user];
        uint256 interest = (borrowBalances[user] * interestRateBasisPoints * timeElapsed) / (10000 * 365 days);
        return borrowBalances[user] + interest;
    }

    function borrow(uint256 amount) external {
        uint256 maxBorrow = (collateralBalances[msg.sender] * collateralFactorBasisPoints) / 10000;
        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        require(currentDebt + amount <= maxBorrow, "exceeds limit");
        borrowBalances[msg.sender] = currentDebt + amount;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;
        // payable(msg.sender).transfer(amount); this has been depreciated due to EIP-1884 (2019 ETH upgrade),
        // which made the 2,300 hard gas limit unsufficient causing legit transfers to fail.
        // next two lines are the replacement
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "transfer failed"); // read as "require that success is true. if it's NOT true, 
        // show the message 'transfer failed'."
    }

    function repay() external payable {
        uint256 currentDebt = calculateInterestAccrued(msg.sender);
        borrowBalances[msg.sender] = currentDebt - msg.value;
        lastInterestAccrualTimestamp[msg.sender] = block.timestamp;
    }

    // liquidations: if collateral value drops below loan value, protocol loses money
    // add lines 23-28 to declare these identifiers
    function liquidate(address borrower) external payable {
        uint256 collateralValue = getCollateralValue(borrower);
        uint256 debtValue = getDebtValue(borrower);

        require(debtValue * 10000 > collateralValue * 8000, "position is healthy");
        require(msg.value >= debtValue, "Insufficient payment");

        uint256 collateral = collateralBalances[borrower];
        borrowBalances[borrower] = 0;
        collateralBalances[borrower] = 0;

        uint256 bonus = collateral * 5 / 100;
        (bool success, ) = payable(msg.sender).call{value: collateral + bonus}("");
        require(success, "transfer failed");
    }

    // flash loans: borrow millions without collateral, but must repay in same transaction (arbitrage,
    // liquidations, collateral swaps)
    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;
        uint256 fee = amount * 9/10000; // 0.09% fee
        // send funds to borrower
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Loan transfer failed");

        // borrower does stuff...

        // make sure they pay it back with the fee
        require(address(this).balance >= balanceBefore + fee, "Not repaid");
    }
}