// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FortKnoxVault is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;

    mapping(address => uint256) private balances;

    uint8 private locked;

    bool public paused;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Paused(address indexed account);
    event Unpaused(address indexed account);

    constructor(IERC20 _token) {
        token = _token;
        locked = 0;
        paused = false;
    }

    modifier nonReentrant() {
        require(locked == 0, "FortKnox: reentrant");
        locked = 1;
        _;
        locked = 0;
    }

    modifier whenNotPaused() {
        require(!paused, "FortKnox: paused");
        _;
    }

    function deposit(uint256 amount) external whenNotPaused {
        require(amount > 0, "FortKnox: zero deposit");
        balances[msg.sender] += amount;

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "FortKnox: zero withdraw");
        uint256 userBal = balances[msg.sender];
        require(userBal >= amount, "FortKnox: insufficient balance");

        balances[msg.sender] = userBal - amount;

        token.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }


    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function rescueTokens(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "FortKnox: zero address");
        token.safeTransfer(to, amount);
    }
}
