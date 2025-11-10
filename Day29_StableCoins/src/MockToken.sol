// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock Collateral", "MCK") {
        _mint(msg.sender, 1_000_000 * (10 ** decimals()));
    }
}
