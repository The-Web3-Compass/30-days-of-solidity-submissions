pragma solidity ^0.8.0;


contract ClickCounter{
  uint public counter;

  function increment() public{
    counter++;
  }
  function decrement() public{
    counter--;
  }
}
