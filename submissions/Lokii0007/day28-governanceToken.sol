pragma solidity >=0.7.0 <0.9.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GOvernanceToken is ERC20 {
  constructor() ERC20("governanceToken", "GVT"){
    _mint(msg.sender, 1000000 * 10 ** decimals()); //* mint 1 millio tokens
  }
}