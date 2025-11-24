// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title SimpleIOU
/// @notice A contract for managing IOU (I Owe You) transactions between registered friends
/// @dev Allows friends to create and settle debts while maintaining balances within the contract
contract SimpleIOU {
    error SimpleIOU_UnAuthorized();
    error SimpleIOU_NoFundsSet(); 
    error SimpleIOU_InsufficientBalance();
    error SimpleIOU_NotEnoughBalance();
    error SimpleIOU_FriendAlreadyExists();
    error SimpleIOU_TransferFailed();
    error SimpleIOU_NotRegistered();
    error SimpleIOU_AmountOwedNotTheSame();
    error SimpleIOU_NoDebt();
    error SimpleIOU_AmountExceedsDebt();


    struct Friend {
        uint256 id;
        uint256 balance;
        bool isFriend;
    }

    event FriendAdded(address indexed friend);
    event FriendRemoved(address indexed friend);
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event SettleDebt(address indexed debtor, address lender);
    event IOUCreated(address indexed debtor, address indexed lender, uint256 amount, string reason);

    address private owner;
    uint256 private friendCounter;
    uint256 private friendRemoved;

    mapping(address => Friend) public friends;

    mapping(address debtor => mapping(address lender  => uint256)) public IOU;

    modifier onlyOwner() {
        if (msg.sender != owner) revert SimpleIOU_UnAuthorized();
        _;
    }
    modifier onlyFriends() {
        if (!friends[msg.sender].isFriend) revert SimpleIOU_UnAuthorized();
        _;
    }

    modifier checkIfFriend(address _friend) {
        if (_friend == address(0) || !friends[_friend].isFriend) revert SimpleIOU_NotRegistered();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Adds a new friend to the contract
    /// @dev Only the owner can add new friends
    /// @param _friend The address of the friend to add
    /// @custom:throws SimpleIOU_FriendAlreadyExists if the friend is already registered
    function addFriend(address _friend) public onlyOwner{
        if (friends[_friend].isFriend) revert SimpleIOU_FriendAlreadyExists();
        friends[_friend] = Friend({
            id: friendCounter++, balance: 0, isFriend: true
        });
        emit FriendAdded(_friend);
    }

    /// @notice Removes a friend from the contract
    /// @dev Only the owner can remove friends
    /// @param _friend The address of the friend to remove
    function removeFriend(address _friend) public onlyOwner{
        friends[_friend].isFriend = false;
        friendRemoved++;
        emit FriendRemoved(_friend);
    }

    /// @notice Allows a friend to deposit funds into their account
    /// @dev Requires the sender to be a registered friend
    /// @custom:throws SimpleIOU_NoFundsSet if the deposit amount is 0
    function depositIntoAccount() public payable onlyFriends {
        if (msg.value == 0) revert SimpleIOU_NoFundsSet();
        friends[msg.sender].balance += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    modifier ableToTransferAmount(uint256 _debtorAmount) {
        if (_debtorAmount == 0) revert SimpleIOU_NoFundsSet();
        if (friends[msg.sender].balance == 0) revert SimpleIOU_InsufficientBalance();
        if (_debtorAmount > friends[msg.sender].balance) revert SimpleIOU_NotEnoughBalance();
        _;
    }

    /// @notice Allows a friend to withdraw their funds from the contract
    /// @dev Only allows withdrawal of own funds and requires sufficient balance
    /// @param _amount The amount to withdraw
    /// @custom:throws SimpleIOU_NoFundsSet if amount is 0
    /// @custom:throws SimpleIOU_InsufficientBalance if sender has no balance
    /// @custom:throws SimpleIOU_NotEnoughBalance if amount exceeds balance
    /// @custom:throws SimpleIOU_TransferFailed if the transfer fails
    function withdrawFromAccount(uint256 _amount) public onlyFriends ableToTransferAmount(_amount) {
    friends[msg.sender].balance -= _amount; 
    
    (bool success,) = payable(msg.sender).call{value: _amount}("");
    if(!success) {
        friends[msg.sender].balance += _amount;  // Revert on failure
        revert SimpleIOU_TransferFailed();
    }
    
    emit Withdrawal(msg.sender, _amount);  
}
    
    /// @notice Creates an IOU (debt) between two friends
    /// @dev The sender becomes the lender and the specified address becomes the debtor
    /// @param _debtor The address of the friend who owes the money
    /// @param _amount The amount of the debt
    /// @param _reason A description of why the debt was created
    /// @custom:throws SimpleIOU_NotRegistered if the debtor is not a registered friend
    function createIOU(address _debtor, uint256 _amount, string memory _reason) public onlyFriends checkIfFriend(_debtor) {
    IOU[_debtor][msg.sender] += _amount;
    emit IOUCreated(_debtor, msg.sender, _amount, _reason);
    }


    /// @notice Settles a debt in full between two friends
    /// @dev Transfers the debt amount from debtor's balance to lender's balance
    /// @param _lender The address of the friend who is owed money
    /// @param _amount The amount to settle (must match the full debt amount)
    /// @custom:throws SimpleIOU_NoDebt if there is no debt to settle
    /// @custom:throws SimpleIOU_AmountOwedNotTheSame if amount doesn't match debt
    function settleDebtFromContract(address _lender, uint256 _amount) public onlyFriends ableToTransferAmount(_amount) {
        // check if the amount equals the amount owed
        if (IOU[msg.sender][_lender] == 0) revert SimpleIOU_NoDebt();
        // for now we want to pay all at once
        if (IOU[msg.sender][_lender] != _amount) revert SimpleIOU_AmountOwedNotTheSame();
        friends[msg.sender].balance -= _amount;
        friends[_lender].balance += _amount;
        // this should resolve it back to 0
        IOU[msg.sender][_lender] -= _amount;

        emit SettleDebt(msg.sender, _lender);
    }

    /// @notice Allows partial settlement of a debt between two friends
    /// @dev Transfers a portion of the debt from debtor's balance to lender's balance
    /// @param _lender The address of the friend who is owed money
    /// @param _amount The partial amount to settle
    /// @custom:throws SimpleIOU_NoDebt if there is no debt to settle
    /// @custom:throws SimpleIOU_AmountExceedsDebt if amount exceeds the debt
    function settlePartialDebt(address _lender, uint256 _amount) public onlyFriends ableToTransferAmount(_amount) {
        if (IOU[msg.sender][_lender] == 0) revert SimpleIOU_NoDebt();
        if (_amount > IOU[msg.sender][_lender]) revert SimpleIOU_AmountExceedsDebt();
        
        friends[msg.sender].balance -= _amount;
        friends[_lender].balance += _amount;
        IOU[msg.sender][_lender] -= _amount;
        
        emit SettleDebt(msg.sender, _lender);
    }

    /// @notice Gets the amount of debt owed to a specific lender
    /// @param _lender The address of the friend who is owed money
    /// @return The amount of debt owed to the lender
    function getDebt(address _lender) external view returns(uint256) {
        return IOU[msg.sender][_lender];
    }

    /// @notice Checks if an address is registered as a friend
    /// @param _address The address to check
    /// @return True if the address is a registered friend, false otherwise
    function isFriendRegistered(address _address) external view returns(bool) {
    return friends[_address].isFriend;
}

    


}