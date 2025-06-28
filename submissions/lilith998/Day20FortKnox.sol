// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DigitalVault is ReentrancyGuard {
    IERC20 public immutable goldToken;
    
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _operators;
    
    event AssetDeposited(address indexed user, uint256 amount);
    event AssetWithdrawn(address indexed user, uint256 amount);
    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);
    
    modifier onlyOperator() {
        require(_operators[msg.sender], "Caller is not operator");
        _;
    }
    
    constructor(address _goldTokenAddress) {
        goldToken = IERC20(_goldTokenAddress);
        _operators[msg.sender] = true;
    }
    
    /**
     * @dev Deposit tokenized gold into the vault
     * @param amount Amount of tokens to deposit (in smallest unit)
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        
        // Transfer tokens from user to vault
        bool success = goldToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
        
        // Update balance after successful transfer
        _balances[msg.sender] += amount;
        
        emit AssetDeposited(msg.sender, amount);
    }
    
    /**
     * @dev Withdraw tokenized gold from the vault
     * @param amount Amount of tokens to withdraw (in smallest unit)
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        
        // Update balance BEFORE transfer to prevent reentrancy
        _balances[msg.sender] -= amount;
        
        // Transfer tokens to user
        bool success = goldToken.transfer(msg.sender, amount);
        require(success, "Transfer failed");
        
        emit AssetWithdrawn(msg.sender, amount);
    }
    
    /**
     * @dev Add emergency operator (for migration/recovery only)
     * @param operator Address to grant operator privileges
     */
    function addOperator(address operator) external onlyOperator {
        _operators[operator] = true;
        emit OperatorAdded(operator);
    }
    
    /**
     * @dev Remove operator privileges
     * @param operator Address to remove operator privileges from
     */
    function removeOperator(address operator) external onlyOperator {
        _operators[operator] = false;
        emit OperatorRemoved(operator);
    }
    
    /**
     * @dev Emergency asset recovery (operator only)
     * @param tokenAddress Address of token to recover
     * @param amount Amount to recover
     */
    function recoverAssets(address tokenAddress, uint256 amount) 
        external 
        onlyOperator 
        nonReentrant 
    {
        IERC20 token = IERC20(tokenAddress);
        require(token != goldToken, "Cannot recover gold tokens");
        token.transfer(msg.sender, amount);
    }
    
    /**
     * @dev Get user's balance
     * @param user Address to check balance for
     * @return Balance of the user
     */
    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }
    
    /**
     * @dev Check operator status
     * @param operator Address to check
     * @return True if operator, false otherwise
     */
    function isOperator(address operator) external view returns (bool) {
        return _operators[operator];
    }
}