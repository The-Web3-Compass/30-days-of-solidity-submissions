pragma solidity >=0.7.0 <0.9.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenA is ERC20 {

  constructor(string memory _name, string memory _symbol, uint256 _totalSupply) ERC20(_name, _symbol){

    _mint(msg.sender, _totalSupply);
  }
}