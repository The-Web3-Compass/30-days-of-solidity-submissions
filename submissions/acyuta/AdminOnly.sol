// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TreasureChest {
    event TreasureAdded(uint256 treasureAmount);
    event TreasureWithdrawn(uint256 treasureAmount);
    event AllowanceSet(address indexed user, uint256 amount);
    event AllowanceRevoked(address indexed user, uint256 revokedAmount);

    error TreasureChest__NotAuthorised();
    error TreasureChest__NotEnoughTreasure();
    error TreasureChest__NotEnoughAllowance();

    struct TreasureAmountAllowance {
        uint256 amount;
        bool allowAccess;
    }

    uint256 private treasureAmount;
    address private immutable i_owner;
    mapping(address => TreasureAmountAllowance) private allowAccess;

    constructor() {
        i_owner = msg.sender;
        allowAccess[i_owner].allowAccess = true;
    }

    function addTreasure() public payable ownerOnly {
        treasureAmount += msg.value;
        emit TreasureAdded(msg.value);
    }

    function approveWithdrawal(
        address _user,
        uint256 _amount
    ) public ownerOnly {
        if (_amount > treasureAmount) revert TreasureChest__NotEnoughTreasure();

        TreasureAmountAllowance memory newAllowance = TreasureAmountAllowance({
            amount: _amount,
            allowAccess: true
        });

        allowAccess[_user] = newAllowance;
        emit AllowanceSet(_user, _amount);
    }

    function withdrawTreasure(uint256 _amount) public {
        if (_amount > treasureAmount) revert TreasureChest__NotEnoughTreasure();
        if (!allowAccess[msg.sender].allowAccess) {
            revert TreasureChest__NotAuthorised();
        }
        if (allowAccess[msg.sender].amount < _amount) {
            revert TreasureChest__NotEnoughAllowance();
        }
        treasureAmount -= _amount;
        allowAccess[msg.sender].amount -= _amount;
        emit TreasureWithdrawn(_amount);
    }

    function revokeAllowance(address _user) public ownerOnly{
        uint256 revokedAmount = allowAccess[_user].amount;
        allowAccess[_user].amount = 0;
        allowAccess[_user].allowAccess = false;
        emit AllowanceRevoked(_user, revokedAmount);
    }

    function getTreasureAmount() public view returns(uint256){
        return treasureAmount;
    }

    modifier ownerOnly() {
        if (msg.sender != i_owner) revert TreasureChest__NotAuthorised();
        _;
    }
}