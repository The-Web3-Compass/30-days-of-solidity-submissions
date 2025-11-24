// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract AdminOnly {
    error AdminOnly_Unauthorized();
    error AdminOnly_TreasureExceeded();
    error AdminOnly_NoAllocation();
    error AdminOnly_WithdrawnAlready();
    error AdminOnly_NoTreasureSet();
    error AdminOnly_AllocationSetAlready();
    error AdminOnly_InsufficientContractBalance();

    struct otherUser {
        address payable userAddress;
        uint256 allowance;
        bool hasWithdrawn;
    }

    mapping (address => otherUser) public otherUsers;

    uint256 treasureAmount;
    uint256 totalAllocation;
    address payable treasureOwner;

    modifier onlyTreasureOwner() {
        if (msg.sender != treasureOwner) revert AdminOnly_Unauthorized();
        _;
    }

    event AllocationPaid(address indexed userAddress, uint256 allowance);
    event TreasureAdded(uint256 amount);
    event AllowanceAllocated(address indexed userAddress, uint256 allowance);

    constructor() {
        treasureOwner = payable(msg.sender);
    }

    function addTreasure(uint256 _amount) public onlyTreasureOwner{
        treasureAmount += _amount;
        emit TreasureAdded(_amount);
    }

    function getFundsAvailableToAllocate() internal view returns(uint256 fundsAvailableToAllocate) {
        fundsAvailableToAllocate = treasureAmount - totalAllocation;
    }

    function allocateAllowance(address _userAddress, uint256 _allowance) public onlyTreasureOwner{
        if (treasureAmount == 0) revert AdminOnly_NoTreasureSet();
        if (otherUsers[_userAddress].allowance != 0) revert AdminOnly_AllocationSetAlready();
        uint256 fundsAvailableToAllocate = treasureAmount - totalAllocation;
        if (_allowance > fundsAvailableToAllocate) revert AdminOnly_TreasureExceeded();
        
       otherUsers[_userAddress].userAddress = payable(_userAddress);
       otherUsers[_userAddress].allowance = _allowance;
       totalAllocation += _allowance;

       emit AllowanceAllocated(_userAddress, _allowance);
    }
 
    function withdraw() public payable {
        otherUser memory currentUser = otherUsers[msg.sender];

        if (currentUser.allowance == 0) revert AdminOnly_NoAllocation();
        // if (currentUser.allowance > treasureAmount) revert AdminOnly_TreasureExceeded();
        if (currentUser.hasWithdrawn) revert AdminOnly_WithdrawnAlready();
        if (currentUser.allowance > address(this).balance) revert AdminOnly_InsufficientContractBalance();

        uint256 amountToWithdraw = currentUser.allowance;

        otherUsers[msg.sender].allowance = 0;
        otherUsers[msg.sender].hasWithdrawn = true;
        totalAllocation -= amountToWithdraw;
        treasureAmount -= amountToWithdraw;

        // currentUser.userAddress.transfer(amountToWithdraw);
        (bool success,) = payable(msg.sender).call{value: amountToWithdraw}("");

        if (!success) {
            otherUsers[msg.sender].allowance= amountToWithdraw;
            otherUsers[msg.sender].hasWithdrawn = false;
            totalAllocation += amountToWithdraw;
            treasureAmount += amountToWithdraw;
            revert("Transfer failed"); 
        }        
        emit AllocationPaid(msg.sender, currentUser.allowance);
    }

    // Owner can withdraw remaining unallocated treasure
    function ownerWithdraw(uint256 _amount) public onlyTreasureOwner {
        uint256 availableFunds = treasureAmount - totalAllocation;
        if (_amount > availableFunds) revert AdminOnly_TreasureExceeded();
        if (_amount > address(this).balance) revert AdminOnly_InsufficientContractBalance();

        treasureAmount -= _amount;

        (bool success,) = treasureOwner.call{value: _amount}("");
        if (!success) {
            treasureAmount += _amount;
            revert("Transfer failed");
        }
    }


    function getTreasure() public view returns (uint256) {
        return treasureAmount;
    }

     function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function resetWithdrawalStatus (address _userAddress) external onlyTreasureOwner{
        if (!otherUsers[_userAddress].hasWithdrawn) return;
        otherUsers[_userAddress].hasWithdrawn = false;  
    }

      // Reset user's allowance back to 0, allowing for re-allocation
    function resetUserAllowance(address _userAddress) external onlyTreasureOwner {
        uint256 currentAllowance = otherUsers[_userAddress].allowance;
        if (currentAllowance == 0) return; // Nothing to reset
        
        otherUsers[_userAddress].allowance = 0;
        otherUsers[_userAddress].hasWithdrawn = false; 
        totalAllocation -= currentAllowance;
        
        emit AllowanceAllocated(_userAddress, 0); 
    }

    function transferTreasureOwnership(address payable _newOwner) external onlyTreasureOwner{
        treasureOwner = _newOwner;
    }

    function getUserAllocation (address _userAddress) public view returns (uint256){
        return otherUsers[_userAddress].allowance;
    }

    function getTotalAllocation() public view returns (uint256) {
        return totalAllocation;
    }

    function getTreasureOwner() public view returns (address) {
        return treasureOwner;
    }
}