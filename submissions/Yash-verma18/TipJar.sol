// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
  
 address public creator;
 
 struct TipInfo {
    uint256 ethAmount;
    string currency;
    uint256 originalAmount; // e.g., $5, €3
}
mapping(address => TipInfo[]) public tips;

event MultiCurrencyDonation(address indexed donor, uint256 ethAmount, string currency, uint256 originalAmount);

 constructor() {
    creator = msg.sender;
 }
  
 modifier onlyCreator () {
    require(msg.sender == creator, "Can only run by admin");
    _;
 }
 
 function buyMeCoffe (string memory currency, uint256 originalAmount) public payable {
    require(msg.value > 0, "You can't donate 0 eth, Have some dignity");
    require(originalAmount > 0, "Original amount must be > 0");

    TipInfo memory tip = TipInfo({
        ethAmount: msg.value,
        currency: currency,
        originalAmount: originalAmount
    });

    tips[msg.sender].push(tip);
    emit MultiCurrencyDonation(msg.sender, msg.value, currency, originalAmount);
    
 }
 
 function withdrawAllMoney () public onlyCreator {
    uint256 amount = address(this).balance;
    require(amount > 0, "No funds to withdraw.");
    (bool success, ) = creator.call{value:amount}("");
    require(success, "Transaction failed");
 }
 
 function getBalance () public view onlyCreator returns (uint256) {
   return address(this).balance;
 }
  
}