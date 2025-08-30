// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract FortKnox {
    address public owner;

    constructor (IERC20 _goldToken) {
        }
    modifier nonReentrant() {
      require(!locked, "Reentrant call");
      locked = true;
        _;
      locked = false;
    }

    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        IERC20(goldToken).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(IERC20(goldToken).balanceOf(address(this)) >= amount, "Insufficient balance");
        IERC20(goldToken).transfer(msg.sender, amount);
    }
}
