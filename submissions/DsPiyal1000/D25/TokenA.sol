// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenA is ERC20 {
    uint256 private immutable _initialSupply;

    constructor() ERC20("Token A", "TKA") {
        _initialSupply = 1000000 * 10 ** decimals();
        _mint(msg.sender, _initialSupply);
    }

    function initialSupply() external view returns (uint256) {
        return _initialSupply;
    }
}