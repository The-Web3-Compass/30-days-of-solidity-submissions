//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract bank{
mapping(address => uint256) public depositbalances;
mapping(address => uint256) public borrowbalances;
mapping(address => uint256) public collateralbalances;
uint256 public interestrate = 500;
uint256 public collateralrate = 7500;
mapping(address => uint256) public lasttime;
event depositnote(address indexed user, uint256 amount);
event withdrawnote(address indexed user, uint256 amount);
event borrownote(address indexed user, uint256 amount);
event repaynote (address indexed user, uint256 amount);
event collateraldeposited(address indexed user, uint256 amount);
event collateralwithdrawn(address indexed user, uint256 amount);
function deposit() external payable {
    require(msg.value > 0, "invalid");
    depositbalances[msg.sender] += msg.value;
    emit depositnote(msg.sender, msg.value);
}
function withdraw(uint256 amount) external {
 require(amount > 0, "invalid");
 require(depositbalances[msg.sender] >= amount, "invalid");
 depositbalances[msg.sender] -= amount;
 payable(msg.sender).transfer(amount);
 emit withdrawnote(msg.sender,amount);
}
function calculateinterest (address user) public view returns (uint256){
        if(borrowbalances[user] == 0){
            return 0;
        }
    uint256 timeelapsed = block.timestamp - lasttime[user];
    uint256 interest = (borrowbalances[user]*interestrate*timeelapsed) / (10000*365 days);
    return borrowbalances[user] + interest;
    }
function depositcollateral() external payable{
    require(msg.value > 0, "invalid");
    collateralbalances[msg.sender] += msg.value;
    emit collateraldeposited(msg.sender, msg.value);
}
function withdrawcollateral(uint256 amount) external {
    require(amount > 0, "invalid");
    require(collateralbalances[msg.sender] >= amount, "invalid");
    uint256 borrowedamount = calculateinterest(msg.sender);
    uint256 requiredcollateral = (borrowedamount * 10000) / collateralrate;
    require(collateralbalances[msg.sender] - amount >= requiredcollateral, "invalid");
    collateralbalances[msg.sender] -= amount;
    payable(msg.sender).transfer(amount);
    emit collateralwithdrawn(msg.sender, amount); 
}
function borrow(uint amount) external {
    require(amount > 0, "invalid");
    require(address(this).balance >= amount, "invalid");
    uint256 maxborrowamount = (collateralbalances[msg.sender]*collateralrate) / 10000;
    uint256 currentdebt = calculateinterest(msg.sender);
    require(currentdebt + amount <= maxborrowamount, "invalid");
    borrowbalances[msg.sender] = currentdebt + amount;
    lasttime[msg.sender] = block.timestamp;
    payable(msg.sender).transfer(amount);
    emit borrownote(msg.sender,amount);
}
function repay() external payable{
    require(msg.value > 0, "invalid");
    uint256 currentdebt = calculateinterest(msg.sender);
    require(currentdebt > 0, "invalid");
    uint256 amounttorepay = msg.value;
    if (amounttorepay > currentdebt){
    amounttorepay = currentdebt;
    payable(msg.sender).transfer(msg.value - currentdebt);
    }
    borrowbalances[msg.sender] = currentdebt - amounttorepay;
    lasttime[msg.sender] = block.timestamp;
    emit repaynote(msg.sender, amounttorepay);
}
function getmaxborrowamount(address user) external view returns (uint256){
    return (collateralbalances[user]*collateralrate) / 10000;
}
function gettotal() external view returns (uint256){
    return address(this).balance;
}
}

