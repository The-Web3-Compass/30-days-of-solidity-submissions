// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract AdminOnly {

    error Not__Owner();
    error Invalid__Owner();
    error Previous__Owner();
    error Insufficient__Funds();
    error Invalid__Withdrawal();
    error Transfer__Failed();
   
    address public  owner;
    uint256 public TreasureAmount;
    mapping(address => uint256) public withdrawalAllowance;
    mapping(address => bool)  public hasWithdrawal;

    constructor() {
        owner = msg.sender;
        TreasureAmount = 0;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Not__Owner();
        }
        _;
    }

    //
    function changeOwner(address _newOwner) public onlyOwner {
        if (_newOwner == address(0)) {
            revert Invalid__Owner();
        }
        if (_newOwner == owner) {
            revert Previous__Owner();
        }
        owner = _newOwner;
    }

    function addTreasure(uint256 _amount) public  onlyOwner {
        TreasureAmount += _amount;
    }

    function approveWithdrawal(address _user, uint256 _amount) public onlyOwner {
        if (_amount > TreasureAmount) {
            revert Insufficient__Funds();
        }
        withdrawalAllowance[_user] = _amount;
    }

    receive()external payable {
        TreasureAmount += msg.value;
    }

    function withdraw(uint256 _amount) public payable  {
        uint256 AccessWithdraw = withdrawalAllowance[msg.sender];
        if (hasWithdrawal[msg.sender]) {
            revert Invalid__Withdrawal();
        }
        if (_amount == 0) {
            revert Invalid__Withdrawal();
        }
        if(_amount > AccessWithdraw){
            revert Insufficient__Funds();
        }
        if(_amount >address(this).balance){
            revert Insufficient__Funds();
        }
       
        
        TreasureAmount -= _amount;
        hasWithdrawal[msg.sender] = true;
        withdrawalAllowance[msg.sender]= 0;
     
    
      (bool success,) = payable(msg.sender).call{value: _amount}("");
      if(!success){
        revert Transfer__Failed();
      }
    

    }


    function getBalance()public view returns(uint256){
        return address(this).balance;   
    }


    
}
