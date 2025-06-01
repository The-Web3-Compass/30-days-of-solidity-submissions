// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenA is ERC20 {
  constructor() ERC20("TokenA", "TKNA"){
    _mint(msg.sender, 1000000 * 10 ** decimals()); //* mint 1 millio tokens
  }
}