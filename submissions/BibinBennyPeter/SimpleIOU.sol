// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleIOU {
  address public owner;
  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public ious;
  mapping (address => bool) public isRecipient;

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function");
    _;
  }

  constructor () public {
    owner = msg.sender;
  }

  function deposit() public payable {
    require(msg.value > 0, "Deposit must be greater than zero");
    balances[msg.sender] += msg.value;
  }

  function sendEth(address payable _recipient) public {
    require(balances[msg.sender] >= msg.value, "Insufficient balance");
    require(recipient != address(0) && is Recipient[_recipient] == true && _recipient != msg.sender, "Invalid recipient address");

    balances[msg.sender] -= msg.value;
    balances[recipient] += msg.value;
    ious[_recipient][msg.sender] += msg.value;
    ious[msg.sender][_recipient] -= msg.value;
    recipient.transfer(msg.value);
  }

  function addRecipient(address _recipient) public onlyOwner {
    require(_recipient != address(0) && !isRecipient[_recipient] && _recipient != msg.sender, "Invalid recipient address");
    isRecipient[_recipient] = true;
  }

  function settle(address _recipient) public {
    require(isRecipient[_recipient], "Recipient not recognized");
    require(ious[msg.sender][_recipient] > 0, "No IOU to settle");

    uint256 amount = ious[msg.sender][_recipient];
    ious[msg.sender][_recipient] = 0;
    balances[msg.sender] -= amount;
    balances[_recipient] += amount;
    payable(_recipient).transfer(amount);
  }

  funtion settle(address _recipient, uint256 _amount) public {
    require(isRecipient[_recipient], "Recipient not recognized");
    require(ious[msg.sender][_recipient] >= 0 && ious[msg.sender][_recipient] >= _amount, "Insufficient IOU to settle");

    ious[msg.sender][_recipient] -= _amount;
    balances[msg.sender] -= _amount;
    balances[_recipient] += _amount;
    payable(_recipient).transfer(_amount);
  }

  funtion setlleAll() public {
    for (address recipient in isRecipient) {
      if (ious[msg.sender][recipient] > 0) {
        settle(recipient);
      }
    }
  }

}
