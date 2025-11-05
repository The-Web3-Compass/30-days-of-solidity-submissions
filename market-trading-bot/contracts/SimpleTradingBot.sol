// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Exchange.sol";

/**
 * @title SimpleTradingBot
 * @notice Automated trading bot for Injective Exchange
 * @dev Uses Injective's Exchange Precompile at 0x0000000000000000000000000000000000000065
 */
contract SimpleTradingBot {
    
    // ========================================
    // CONSTANTS & IMMUTABLES
    // ========================================
    
    address public constant EXCHANGE_PRECOMPILE = 0x0000000000000000000000000000000000000065;
    IExchangeModule public immutable exchange;
    
    // Order type constants (matching Injective protocol)
    string public constant ORDER_TYPE_BUY = "buy";
    string public constant ORDER_TYPE_SELL = "sell";
    
    // ========================================
    // STATE VARIABLES
    // ========================================
    
    address public owner;
    bool public tradingPaused;
    string public subaccountId;
    
    // ========================================
    // EVENTS
    // ========================================
    
    event SpotOrderPlaced(
        string indexed marketId,
        bool isBuy,
        uint256 price,
        uint256 quantity,
        string orderHash,
        uint256 timestamp
    );
    
    // ========================================
    // MODIFIERS
    // ========================================
    
    modifier onlyOwner() {
        require(msg.sender == owner, "SimpleTradingBot: Caller is not the owner");
        _;
    }
    
    modifier whenNotPaused() {
        require(!tradingPaused, "SimpleTradingBot: Trading is paused");
        _;
    }
    
    modifier validAmount(uint256 amount) {
        require(amount > 0, "SimpleTradingBot: Amount must be greater than zero");
        _;
    }
    
    // ========================================
    // CONSTRUCTOR
    // ========================================
    
    /**
     * @notice Initializes the trading bot and creates a subaccount
     * @param _subaccountNonce The nonce for subaccount creation (use 1 for first subaccount, 2 for second, etc.)
     * @dev Automatically generates subaccount ID: [contract_address(20 bytes)][nonce(12 bytes)] (no 0x prefix)
     */
    constructor(uint96 _subaccountNonce) {
        owner = msg.sender;
        exchange = IExchangeModule(EXCHANGE_PRECOMPILE);
        tradingPaused = false;
        
        // Generate subaccount ID from contract address + nonce (no 0x prefix)
        subaccountId = generateSubaccountId(address(this), _subaccountNonce);
    }
    
    // ========================================
    // SUBACCOUNT FUNCTIONS
    // ========================================
    
    /**
     * @notice Gets the current subaccount ID
     * @return The subaccount ID as a hex string
     */
    function getSubaccountId() public view returns (string memory) {
        return subaccountId;
    }
    
    // ========================================
    // SPOT TRADING FUNCTIONS
    // ========================================
    
    /**
     * @notice Places a spot limit order
     * @param _marketId The market identifier
     * @param _price Order price (18 decimals)
     * @param _quantity Order quantity (18 decimals)
     * @param _isBuy True for buy order, false for sell
     * @return orderHash The hash of the created order
     */
    function placeSpotLimitOrder(
        string calldata _marketId,
        uint256 _price,
        uint256 _quantity,
        bool _isBuy
    ) 
        external 
        onlyOwner 
        whenNotPaused
        validAmount(_quantity) 
        validAmount(_price)
        returns (string memory orderHash)
    {
        require(bytes(_marketId).length > 0, "SimpleTradingBot: Invalid market ID");
        
        // Create spot order struct with flattened fields
        IExchangeModule.SpotOrder memory order = IExchangeModule.SpotOrder({
            marketID: _marketId,
            subaccountID: subaccountId,
            feeRecipient: "",  // Empty string for default fee recipient
            price: _price,
            quantity: _quantity,
            cid: "",
            orderType: _isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
            triggerPrice: 0
        });
        
        try exchange.createSpotLimitOrder(address(this), order)
            returns (IExchangeModule.CreateSpotLimitOrderResponse memory response) {
                emit SpotOrderPlaced(
                    _marketId,
                    _isBuy,
                    _price,
                    _quantity,
                    response.orderHash,
                    block.timestamp
                );
                return response.orderHash;
            } catch Error(string memory reason) {
                revert(string(abi.encodePacked("Order placement failed: ", reason)));
            } catch (bytes memory) {
                revert("Order placement failed with unknown error");
            }
    }
    
    /**
     * @notice Cancels a spot order
     * @param _marketId The market ID
     * @param _orderHash The order hash to cancel (as hex string)
     * @return success Whether the cancellation succeeded
     */
    function cancelSpotOrder(
        string calldata _marketId,
        string calldata _orderHash
    ) 
        external 
        onlyOwner 
        returns (bool success) 
    {
        require(bytes(_marketId).length > 0, "SimpleTradingBot: Invalid market ID");
        require(bytes(_orderHash).length > 0, "SimpleTradingBot: Invalid order hash");
        
        try exchange.cancelSpotOrder(
            address(this), 
            _marketId, 
            subaccountId,
            _orderHash, 
            ""
        ) returns (bool result) {
            return result;
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("Order cancellation failed: ", reason)));
        } catch (bytes memory) {
            revert("Order cancellation failed with unknown error");
        }
    }
    
    // ========================================
    // DEPOSIT/WITHDRAWAL FUNCTIONS
    // ========================================
    
    /**
     * @notice Deposits funds into the exchange subaccount
     * @param _denom Token denomination (e.g., "inj", "peggy0x...")
     * @param _amount Amount to deposit
     * @return success Whether the deposit succeeded
     * @dev For native INJ deposits, uses contract's balance (no msg.value needed)
     * @dev For peggy tokens, approve the exchange precompile first
     */
    function depositToExchange(
        string calldata _denom,
        uint256 _amount
    ) 
        external 
        onlyOwner 
        validAmount(_amount)
        returns (bool success) 
    {
        // For native INJ deposits, check contract has sufficient balance
        if (keccak256(bytes(_denom)) == keccak256(bytes("inj"))) {
            require(address(this).balance >= _amount, "SimpleTradingBot: Insufficient contract balance");
        }
        
        // Call deposit WITHOUT sending value - use the configured subaccount ID
        try exchange.deposit(address(this), subaccountId, _denom, _amount) 
            returns (bool result) {
                return result;
            } catch Error(string memory reason) {
                revert(string(abi.encodePacked("Deposit failed: ", reason)));
            } catch (bytes memory) {
                revert("Deposit failed with unknown error");
            }
    }
    
    // ========================================
    // QUERY FUNCTIONS
    // ========================================
    
    /**
     * @notice Queries the contract's subaccount deposit for a given denomination
     * @param _denom Token denomination
     * @return availableBalance Available balance
     * @return totalBalance Total balance (including locked in orders)
     */
    function getSubaccountBalance(string calldata _denom) 
        external 
        view 
        returns (uint256 availableBalance, uint256 totalBalance) 
    {
        return exchange.subaccountDeposit(subaccountId, _denom);
    }
    
    /**
     * @notice Gets comprehensive contract information
     * @return contractAddress This contract's address
     * @return contractOwner The owner address
     * @return isPaused Whether trading is paused
     * @return currentSubaccountId The subaccount ID
     */
    function getContractInfo() 
        external 
        view 
        returns (
            address contractAddress,
            address contractOwner,
            bool isPaused,
            string memory currentSubaccountId
        ) 
    {
        return (
            address(this),
            owner,
            tradingPaused,
            subaccountId
        );
    }
    
    // ========================================
    // RECEIVE & FALLBACK
    // ========================================
    
    /**
     * @notice Receives native tokens
     */
    receive() external payable {}
    
    /**
     * @notice Fallback function
     */
    fallback() external payable {
        revert("SimpleTradingBot: Invalid function call");
    }
    
    // ========================================
    // INTERNAL HELPER FUNCTIONS
    // ========================================
    
    /**
     * @notice Converts bytes to hex string WITHOUT 0x prefix
     * @dev Used for subaccount ID generation per Injective format
     * @param _bytes The bytes to convert
     * @return The hex string representation (no 0x prefix)
     */
    function bytesToHexString(bytes memory _bytes) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(_bytes.length * 2);
        
        for (uint256 i = 0; i < _bytes.length; i++) {
            str[i * 2] = alphabet[uint8(_bytes[i] >> 4)];
            str[i * 2 + 1] = alphabet[uint8(_bytes[i] & 0x0f)];
        }
        
        return string(str);
    }
    
    /**
     * @notice Generates a subaccount ID from an address and nonce
     * @param _addr The address (typically the contract address)
     * @param _nonce The subaccount nonce (12 bytes / 96 bits)
     * @return The subaccount ID in format: [address(40 hex chars)][nonce(24 hex chars)] (NO 0x prefix)
     * @dev Subaccount ID format on Injective: 20 bytes address + 12 bytes nonce = 64 hex chars (no 0x)
     */
    function generateSubaccountId(address _addr, uint96 _nonce) internal pure returns (string memory) {
        // Combine address (20 bytes) + nonce (12 bytes) = 32 bytes
        bytes memory combined = abi.encodePacked(_addr, _nonce);
        
        // Convert to hex string WITHOUT 0x prefix (Injective precompile format)
        return bytesToHexString(combined);
    }
}