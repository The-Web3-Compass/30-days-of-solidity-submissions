pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FortKnoxVault is Ownable {
    using SafeERC20 for IERC20;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed recipient, uint256 amount);
    event Paused(bool paused);

    IERC20 public immutable goldToken;
    mapping(address => uint256) private balances;
    bool public paused;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor(IERC20 _goldToken) {
        require(address(_goldToken) != address(0));
        goldToken = _goldToken;
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status == _NOT_ENTERED);
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    function deposit(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0);
        balances[msg.sender] += amount;
        goldToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0);
        uint256 userBal = balances[msg.sender];
        require(userBal >= amount);
        unchecked {
            balances[msg.sender] = userBal - amount;
        }
        goldToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function withdrawAll() external whenNotPaused nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0);
        balances[msg.sender] = 0;
        goldToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    function emergencyWithdraw(address recipient, uint256 amount) external onlyOwner nonReentrant {
        require(recipient != address(0));
        require(amount > 0);
        goldToken.safeTransfer(recipient, amount);
        emit EmergencyWithdraw(recipient, amount);
    }
}
