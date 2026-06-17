// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initial) ERC20(name, symbol) {
        if (initial > 0) {
            _mint(msg.sender, initial);
        }
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
