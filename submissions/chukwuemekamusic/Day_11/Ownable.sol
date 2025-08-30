
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Ownable {
    error Ownable_SameAddress();
    error Ownable_InvalidAddress();
    error Ownable_PendingOwnership();
    error Ownable_UnAuthorized();
    error Ownable_TransferFailed();
    error Ownable_InsufficientBalance();
    error Ownable_InvalidAmount();
    
    address private s_owner;
    address private s_pendingOwner;

    modifier onlyOwner {
        if (msg.sender != s_owner) revert Ownable_UnAuthorized();
        _;
    }

    modifier onlyPendingOwner {
        if (msg.sender != s_pendingOwner) revert Ownable_UnAuthorized();
        _;
    }

    event InitiatedTransferOwnership(address indexed owner, address indexed pendingOwner);
    event TransferredOwnership(address indexed previousOwner, address indexed newOwner);
    event WithdrawSuccessful(address indexed recipient, uint256 amount);
    event OwnershipRenounced(address indexed previousOwner);
    
    constructor() {
        s_owner = msg.sender;
    }
    
    function getOwner() public view returns (address) {
        return s_owner;
    }

    function getPendingOwner() external view returns (address) {
        return s_pendingOwner;
    }
    
    /**
     * @dev Transfer ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        if (_newOwner == address(0)) revert Ownable_InvalidAddress();
        if (_newOwner == s_owner) revert Ownable_SameAddress();
        if (s_pendingOwner != address(0)) revert Ownable_PendingOwnership();
    
        s_pendingOwner = _newOwner;
        emit InitiatedTransferOwnership(s_owner, _newOwner);
    }

    /**
     * @dev Accept ownership transfer. Can only be called by pending owner.
     */
    function acceptOwnership() external onlyPendingOwner {
        address oldOwner = s_owner;
        s_owner = msg.sender;
        s_pendingOwner = address(0);
        emit TransferredOwnership(oldOwner, s_owner);  
    }

    /**
     * @dev Cancel pending ownership transfer. Can only be called by current owner.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        if (s_pendingOwner == address(0)) revert Ownable_InvalidAddress();
        s_pendingOwner = address(0);
    }

    /**
     * @dev Renounce ownership permanently. Can only be called by current owner.
     * WARNING: This will leave the contract without an owner!
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipRenounced(s_owner);
        emit TransferredOwnership(s_owner, address(0));
        s_owner = address(0);
        s_pendingOwner = address(0);
    }

    /**
     * @dev Withdraw all ETH from contract to owner.
     */
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert Ownable_InsufficientBalance();
        
        (bool success,) = payable(s_owner).call{value: balance}("");
        if (!success) revert Ownable_TransferFailed();
        
        emit WithdrawSuccessful(s_owner, balance);
    }
    
    /**
     * @dev Withdraw specific amount of ETH from contract to owner.
     */
    function withdraw(uint256 _amount) public virtual onlyOwner {
        if (_amount == 0) revert Ownable_InvalidAmount();
        if (_amount > address(this).balance) revert Ownable_InsufficientBalance();
        
        (bool success,) = payable(s_owner).call{value: _amount}("");
        if (!success) revert Ownable_TransferFailed();
        
        emit WithdrawSuccessful(s_owner, _amount);
    }

    /**
     * @dev Get contract balance.
     */
    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }
}