// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleERC20 {
    string public tokenName = "SimpleToken";
    string public tokenSymbol = "SIM";
    uint8 public tokenDecimals = 18;
    uint256 public tokenTotalSupply;

    mapping(address => uint256) public walletBalances;
    mapping(address => mapping(address => uint256)) public spendingAllowance;

    event TokensTransferred(address indexed sender, address indexed receiver, uint256 amount);
    event ApprovalGranted(address indexed owner, address indexed spender, uint256 amount);

    constructor(uint256 initialSupplyUnits) {
        tokenTotalSupply = initialSupplyUnits * (10 ** uint256(tokenDecimals));
        walletBalances[msg.sender] = tokenTotalSupply;
        emit TokensTransferred(address(0), msg.sender, tokenTotalSupply);
    }

    function sendTokens(address recipient, uint256 amount) public returns (bool) {
        require(walletBalances[msg.sender] >= amount, "Insufficient funds");
        _internalTransfer(msg.sender, recipient, amount);
        return true;
    }

    function authorizeSpender(address spender, uint256 amount) public returns (bool) {
        spendingAllowance[msg.sender][spender] = amount;
        emit ApprovalGranted(msg.sender, spender, amount);
        return true;
    }

    function delegatedTransfer(address sender, address recipient, uint256 amount) public returns (bool) {
        require(walletBalances[sender] >= amount, "Sender lacks funds");
        require(spendingAllowance[sender][msg.sender] >= amount, "Allowance exceeded");

        spendingAllowance[sender][msg.sender] -= amount;
        _internalTransfer(sender, recipient, amount);
        return true;
    }

    function _internalTransfer(address sender, address recipient, uint256 amount) internal {
        require(recipient != address(0), "Recipient cannot be zero address");
        walletBalances[sender] -= amount;
        walletBalances[recipient] += amount;
        emit TokensTransferred(sender, recipient, amount);
    }
}
