// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


contract SimpleEscrow {
    
    enum EscrowState { 
        AWAITING_PAYMENT,     
        AWAITING_DELIVERY,    
        COMPLETE,            
        DISPUTED,            
        CANCELLED           
    }

    
    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;

    
    uint256 public amount;
    EscrowState public state;
    uint256 public depositTime;
    uint256 public deliveryTimeout;

    
    event PaymentDeposited(address indexed buyer, uint256 amount);
    event DeliveryConfirmed(address indexed buyer, address indexed seller, uint256 amount);
    event DisputeRaised(address indexed initiator, string reason);
    event DisputeResolved(address indexed arbiter, address recipient, uint256 amount, string resolution);
    event EscrowCancelled(address indexed initiator, string reason);
    event DeliveryTimeoutReached(address indexed buyer);
    event FundsReleased(address indexed recipient, uint256 amount);

    
    error OnlyBuyer();
    error OnlySeller();
    error OnlyArbiter();
    error InvalidState();
    error InvalidAmount();
    error InsufficientBalance();
    error TimeoutNotReached();
    error NoDisputeToResolve();
    error TransferFailed();

    
    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout) {
        require(_seller != address(0), "Seller cannot be zero address");
        require(_arbiter != address(0), "Arbiter cannot be zero address");
        require(_deliveryTimeout > 0, "Delivery timeout must be greater than zero");

        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        deliveryTimeout = _deliveryTimeout;
        state = EscrowState.AWAITING_PAYMENT;
    }

    
    receive() external payable {
        revert("Direct payments not allowed. Use deposit() function.");
    }

    
    function deposit() external payable {
        
        if (msg.sender != buyer) {
            revert OnlyBuyer();
        }
        
        
        if (state != EscrowState.AWAITING_PAYMENT) {
            revert InvalidState();
        }
        
        
        if (msg.value == 0) {
            revert InvalidAmount();
        }

        
        amount = msg.value;
        state = EscrowState.AWAITING_DELIVERY;
        depositTime = block.timestamp;

        emit PaymentDeposited(buyer, amount);
    }

    
    function confirmDelivery() external {
        if (msg.sender != buyer) {
            revert OnlyBuyer();
        }
        
        if (state != EscrowState.AWAITING_DELIVERY) {
            revert InvalidState();
        }

        state = EscrowState.COMPLETE;
        
        
        (bool success, ) = payable(seller).call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }

        emit DeliveryConfirmed(buyer, seller, amount);
        emit FundsReleased(seller, amount);
    }

    
    function raiseDispute(string calldata reason) external {
        
        if (msg.sender != buyer && msg.sender != seller) {
            revert("Only buyer or seller can raise dispute");
        }
        
        if (state != EscrowState.AWAITING_DELIVERY) {
            revert InvalidState();
        }

        state = EscrowState.DISPUTED;
        emit DisputeRaised(msg.sender, reason);
    }

    
    function resolveDispute(bool releaseToSeller, string calldata resolution) external {
        if (msg.sender != arbiter) {
            revert OnlyArbiter();
        }
        
        if (state != EscrowState.DISPUTED) {
            revert NoDisputeToResolve();
        }

        state = EscrowState.COMPLETE;
        address recipient = releaseToSeller ? seller : buyer;

        
        (bool success, ) = payable(recipient).call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }

        emit DisputeResolved(arbiter, recipient, amount, resolution);
        emit FundsReleased(recipient, amount);
    }

    
    function cancelAfterTimeout() external {
        if (msg.sender != buyer) {
            revert OnlyBuyer();
        }
        
        if (state != EscrowState.AWAITING_DELIVERY) {
            revert InvalidState();
        }
        
        if (block.timestamp < depositTime + deliveryTimeout) {
            revert TimeoutNotReached();
        }

        state = EscrowState.CANCELLED;
        
        
        (bool success, ) = payable(buyer).call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }

        emit EscrowCancelled(buyer, "Delivery timeout reached");
        emit DeliveryTimeoutReached(buyer);
        emit FundsReleased(buyer, amount);
    }

    
    function cancelMutual(string calldata reason) external {
        
        if (msg.sender != buyer && msg.sender != seller) {
            revert("Only buyer or seller can cancel mutually");
        }
        
        if (state != EscrowState.AWAITING_DELIVERY && state != EscrowState.AWAITING_PAYMENT) {
            revert InvalidState();
        }

        EscrowState previousState = state;
        state = EscrowState.CANCELLED;

        
        if (previousState == EscrowState.AWAITING_DELIVERY) {
            (bool success, ) = payable(buyer).call{value: amount}("");
            if (!success) {
                revert TransferFailed();
            }
            emit FundsReleased(buyer, amount);
        }

        emit EscrowCancelled(msg.sender, reason);
    }

    
    function getTimeLeft() external view returns (uint256 timeLeft) {
        if (state != EscrowState.AWAITING_DELIVERY) {
            return 0;
        }
        
        uint256 deadline = depositTime + deliveryTimeout;
        if (block.timestamp >= deadline) {
            return 0;
        }
        
        return deadline - block.timestamp;
    }

    
    function getContractBalance() external view returns (uint256 balance) {
        return address(this).balance;
    }

    
    function getEscrowDetails() external view returns (
        address _buyer,
        address _seller,
        address _arbiter,
        uint256 _amount,
        EscrowState _state,
        uint256 _depositTime,
        uint256 _deliveryTimeout,
        uint256 _timeLeft,
        uint256 _contractBalance
    ) {
        _buyer = buyer;
        _seller = seller;
        _arbiter = arbiter;
        _amount = amount;
        _state = state;
        _depositTime = depositTime;
        _deliveryTimeout = deliveryTimeout;
        _timeLeft = this.getTimeLeft();
        _contractBalance = address(this).balance;
    }

    
    function canCancel() external view returns (bool cancelable) {
        return state == EscrowState.AWAITING_DELIVERY && 
               block.timestamp >= depositTime + deliveryTimeout;
    }

    
    function getStateName() external view returns (string memory stateName) {
        if (state == EscrowState.AWAITING_PAYMENT) return "AWAITING_PAYMENT";
        if (state == EscrowState.AWAITING_DELIVERY) return "AWAITING_DELIVERY";
        if (state == EscrowState.COMPLETE) return "COMPLETE";
        if (state == EscrowState.DISPUTED) return "DISPUTED";
        if (state == EscrowState.CANCELLED) return "CANCELLED";
        return "UNKNOWN";
    }

    
    function emergencyStop(address recipient, string calldata reason) external {
        if (msg.sender != arbiter) {
            revert OnlyArbiter();
        }
        
        require(recipient == buyer || recipient == seller, "Recipient must be buyer or seller");
        
        uint256 contractBalance = address(this).balance;
        if (contractBalance == 0) {
            revert InsufficientBalance();
        }

        state = EscrowState.CANCELLED;
        
        (bool success, ) = payable(recipient).call{value: contractBalance}("");
        if (!success) {
            revert TransferFailed();
        }

        emit EscrowCancelled(arbiter, string(abi.encodePacked("Emergency stop: ", reason)));
        emit FundsReleased(recipient, contractBalance);
    }
}