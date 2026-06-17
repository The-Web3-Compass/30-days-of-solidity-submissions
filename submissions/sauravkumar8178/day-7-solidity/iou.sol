// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


contract IOU {
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event Deposit(address indexed who, uint256 amount);
    event Withdraw(address indexed who, uint256 amount);
    event InternalTransfer(address indexed from, address indexed to, uint256 amount);
    event DebtRecorded(address indexed borrower, address indexed lender, uint256 amount);
    event DebtReduced(address indexed borrower, address indexed lender, uint256 amount);
    event DebtForgiven(address indexed borrower, address indexed lender, uint256 amount);
    event DebtSettledOnChain(address indexed borrower, address indexed lender, uint256 amount, uint256 repaidWith);

    address public owner;

    mapping(address => uint256) private balances;

    mapping(address => mapping(address => uint256)) private debts;

    mapping(address => bool) public isMember;

    uint256 private _locked = 1;
    modifier nonReentrant() {
        require(_locked == 1, "Reentrant call");
        _locked = 2;
        _;
        _locked = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Not a member");
        _;
    }

    constructor(address[] memory initialMembers) {
        owner = msg.sender;
        isMember[owner] = true;
        emit MemberAdded(owner);

        for (uint i = 0; i < initialMembers.length; i++) {
            if (initialMembers[i] != address(0) && !isMember[initialMembers[i]]) {
                isMember[initialMembers[i]] = true;
                emit MemberAdded(initialMembers[i]);
            }
        }
    }

    function addMember(address _member) external onlyOwner {
        require(_member != address(0), "Zero address");
        require(!isMember[_member], "Already member");
        isMember[_member] = true;
        emit MemberAdded(_member);
    }

    function removeMember(address _member) external onlyOwner {
        require(isMember[_member], "Not a member");
        isMember[_member] = false;
        emit MemberRemoved(_member);
    }

    receive() external payable {
        _deposit(msg.sender, msg.value);
    }

    fallback() external payable {
        _deposit(msg.sender, msg.value);
    }

    function deposit() external payable onlyMember {
        _deposit(msg.sender, msg.value);
    }

    function _deposit(address _who, uint256 _amount) internal {
        require(_amount > 0, "Zero deposit");
        balances[_who] += _amount;
        emit Deposit(_who, _amount);
    }

    function withdraw(uint256 amount) external nonReentrant onlyMember {
        require(amount > 0, "Zero withdraw");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    function transferInternal(address to, uint256 amount) external onlyMember {
        require(isMember[to], "Receiver not a member");
        require(to != address(0), "Zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit InternalTransfer(msg.sender, to, amount);
    }

    function recordDebt(address borrower, address lender, uint256 amount) external onlyMember {
        require(amount > 0, "Zero amount");
        require(isMember[borrower] && isMember[lender], "Both must be members");
        require(borrower != lender, "Same person");

        debts[borrower][lender] += amount;

        emit DebtRecorded(borrower, lender, amount);
    }

    function reduceDebt(address borrower, address lender, uint256 amount) external onlyOwner {
        require(amount > 0, "Zero amount");
        uint256 current = debts[borrower][lender];
        require(current >= amount, "Reduce > debt");
        debts[borrower][lender] = current - amount;
        emit DebtReduced(borrower, lender, amount);
    }

    function forgiveDebt(address borrower, address lender) external onlyOwner {
        uint256 amt = debts[borrower][lender];
        if (amt > 0) {
            debts[borrower][lender] = 0;
            emit DebtForgiven(borrower, lender, amt);
        }
    }

    function repayOnChain(address payable lender, uint256 amount) external payable nonReentrant onlyMember {
        require(amount > 0, "Zero repay");
        require(isMember[lender], "Lender must be member");

        uint256 currentDebt = debts[msg.sender][lender];
        require(currentDebt >= amount, "Repay > debt");

        uint256 remaining = amount;
        if (msg.value > 0) {
            if (msg.value >= remaining) {
                (bool s, ) = lender.call{value: remaining}("");
                require(s, "Pay lender failed (msg.value)");
                emit DebtSettledOnChain(msg.sender, lender, amount, remaining);

                uint256 extra = msg.value - remaining;
                if (extra > 0) {
                    balances[msg.sender] += extra;
                    emit Deposit(msg.sender, extra);
                }
                debts[msg.sender][lender] = currentDebt - amount;
                return;
            } else {
                (bool s2, ) = lender.call{value: msg.value}("");
                require(s2, "Partial pay failed");
                remaining -= msg.value;
            }
        }

        require(balances[msg.sender] >= remaining, "Insufficient internal balance");
        balances[msg.sender] -= remaining;

        (bool s3, ) = lender.call{value: remaining}("");
        require(s3, "Transfer to lender failed");

        debts[msg.sender][lender] = currentDebt - amount;

        emit DebtSettledOnChain(msg.sender, lender, amount, msg.value + remaining);
    }

    function balanceOf(address who) external view returns (uint256) {
        return balances[who];
    }

    function debtOf(address borrower, address lender) external view returns (uint256) {
        return debts[borrower][lender];
    }

    function totalDebtOf(address borrower, address[] calldata lenders) external view returns (uint256) {
        uint256 total = 0;
        for (uint i = 0; i < lenders.length; i++) {
            total += debts[borrower][lenders[i]];
        }
        return total;
    }

    function emergencyWithdraw(address payable to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Zero address");
        (bool s, ) = to.call{value: amount}("");
        require(s, "Emergency withdraw failed");
    }
}
