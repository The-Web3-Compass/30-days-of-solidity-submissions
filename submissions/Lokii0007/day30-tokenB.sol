// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenB is ERC20 {
  constructor() ERC20("TokenB", "TKNB"){
    _mint(msg.sender, 1000000 * 10 ** decimals()); //* mint 1 millio tokens
  }
}