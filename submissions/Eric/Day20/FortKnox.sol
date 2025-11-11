//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title FortKnot
 * @author Eric (https://github.com/0xxEric)
 * @notice SimpleVault.sol
 * @custom:project 30-days-of-solidity-submissions: Day20
 */
/*
  SimpleVault.sol
  - A minimal vault for tokenized gold (or any ERC20 token)
  - Prevents reentrancy using a nonReentrant modifier (simple status lock)
  - Uses OpenZeppelin's SafeERC20 for safe token transfers
*/

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleVault {
    using SafeERC20 for IERC20;

    // balances[tokenAddress][user] => amount
    mapping(address => mapping(address => uint256)) private balances;

    // reentrancy status: 1 = NOT_ENTERED, 2 = ENTERED
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    // events
    event Deposited(address indexed token, address indexed user, uint256 amount);
    event Withdrawn(address indexed token, address indexed user, uint256 amount);

    constructor() {
        _status = _NOT_ENTERED;
    }

    /// @notice nonReentrant modifier to prevent reentrancy
    modifier nonReentrant() {
        require(_status == _NOT_ENTERED, "SimpleVault: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    /// @notice Deposit `amount` of `token` into the vault for msg.sender
    /// @dev User must approve this contract to spend `amount` tokens beforehand
    function deposit(IERC20 token, uint256 amount) external {
        require(amount > 0, "SimpleVault: zero amount");
        // transfer tokens from user to this contract (may revert)
        token.safeTransferFrom(msg.sender, address(this), amount);
        // update the user's balance for this token
        balances[address(token)][msg.sender] += amount;

        emit Deposited(address(token), msg.sender, amount);
    }

    /// @notice Withdraw `amount` of `token` previously deposited
    /// @dev Protected by nonReentrant. Uses checks-effects-interactions pattern.
    function withdraw(IERC20 token, uint256 amount) external nonReentrant {
        require(amount > 0, "SimpleVault: zero amount");
        uint256 userBal = balances[address(token)][msg.sender];
        require(userBal >= amount, "SimpleVault: insufficient balance");

        // --- Effects: update balance BEFORE external interaction ---
        balances[address(token)][msg.sender] = userBal - amount;

        // --- Interaction: transfer tokens to the caller ---
        token.safeTransfer(msg.sender, amount);

        emit Withdrawn(address(token), msg.sender, amount);
    }

    /// @notice View the vault balance for `user` and `token`
    function balanceOf(IERC20 token, address user) external view returns (uint256) {
        return balances[address(token)][user];
    }
}
