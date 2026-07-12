// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title MyFirstToken
 * @dev Implementation of a basic ERC20 token
 * @notice This is a simple token contract demonstrating core ERC20 functionality
 * 
 * Key Concepts:
 * - ERC20 Standard: A standard interface for fungible tokens on Ethereum
 * - totalSupply: The total number of tokens in existence
 * - balanceOf: Track how many tokens each address owns
 * - transfer: Move tokens from one address to another
 */
contract MyFirstToken {
    
    // ===========================================
    // STATE VARIABLES
    // ===========================================
    
    /// @notice The name of the token (e.g., "Bitcoin")
    string public name;
    
    /// @notice The symbol/ticker of the token (e.g., "BTC")
    string public symbol;
    
    /// @notice Number of decimal places (18 is standard, like ETH)
    /// @dev This means 1 token = 1 * 10^18 base units
    uint8 public decimals;
    
    /// @notice Total supply of tokens in existence
    /// @dev This is the sum of all tokens across all addresses
    uint256 public totalSupply;
    
    /// @notice Mapping to track balance of each address
    /// @dev address => balance (in base units)
    mapping(address => uint256) public balanceOf;
    
    /// @notice Mapping to track allowances for spending on behalf of others
    /// @dev owner => (spender => amount)
    mapping(address => mapping(address => uint256)) public allowance;
    
    // ===========================================
    // EVENTS
    // ===========================================
    
    /// @notice Emitted when tokens are transferred
    /// @param from The address sending tokens
    /// @param to The address receiving tokens
    /// @param value The amount of tokens transferred
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /// @notice Emitted when an allowance is set
    /// @param owner The address that owns the tokens
    /// @param spender The address allowed to spend tokens
    /// @param value The amount of tokens approved
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // ===========================================
    // CONSTRUCTOR
    // ===========================================
    
    /**
     * @notice Creates a new token with initial supply
     * @dev The entire supply is minted to the contract deployer
     * @param _name The name of the token
     * @param _symbol The symbol/ticker of the token
     * @param _decimals Number of decimal places
     * @param _initialSupply Initial supply of tokens (in whole units, not base units)
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        
        // Calculate total supply in base units
        // For example: if _initialSupply = 1000 and decimals = 18,
        // totalSupply = 1000 * 10^18 base units
        totalSupply = _initialSupply * (10 ** uint256(_decimals));
        
        // Give all tokens to the contract creator
        balanceOf[msg.sender] = totalSupply;
        
        // Emit transfer event from address(0) to indicate minting
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    // ===========================================
    // CORE ERC20 FUNCTIONS
    // ===========================================
    
    /**
     * @notice Transfer tokens from your address to another address
     * @dev This is the main function users call to send tokens
     * @param _to The address to receive tokens
     * @param _value The amount of tokens to send (in base units)
     * @return success Returns true if transfer succeeds
     * 
     * Requirements:
     * - `_to` cannot be the zero address
     * - Caller must have at least `_value` tokens
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // Prevent burning tokens by accident (sending to address(0))
        require(_to != address(0), "Cannot transfer to zero address");
        
        // Check if sender has enough tokens
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        
        // Subtract tokens from sender
        balanceOf[msg.sender] -= _value;
        
        // Add tokens to recipient
        balanceOf[_to] += _value;
        
        // Emit transfer event
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    /**
     * @notice Approve another address to spend tokens on your behalf
     * @dev This is used for delegated transfers (e.g., DEX contracts)
     * @param _spender The address authorized to spend
     * @param _value The maximum amount they can spend
     * @return success Returns true if approval succeeds
     * 
     * Example: Alice approves a DEX contract to spend 100 tokens,
     * then the DEX can call transferFrom to move those tokens
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Cannot approve zero address");
        
        // Set the allowance
        allowance[msg.sender][_spender] = _value;
        
        // Emit approval event
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    /**
     * @notice Transfer tokens on behalf of another address
     * @dev Used after approve() has been called. Common in DeFi protocols
     * @param _from The address to send tokens from
     * @param _to The address to receive tokens
     * @param _value The amount of tokens to transfer
     * @return success Returns true if transfer succeeds
     * 
     * Requirements:
     * - `_from` must have approved the caller for at least `_value` tokens
     * - `_from` must have at least `_value` tokens
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(_from != address(0), "Cannot transfer from zero address");
        
        // Check if _from has enough tokens
        require(balanceOf[_from] >= _value, "Insufficient balance");
        
        // Check if caller has enough allowance
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");
        
        // Subtract from sender
        balanceOf[_from] -= _value;
        
        // Add to recipient
        balanceOf[_to] += _value;
        
        // Reduce allowance
        allowance[_from][msg.sender] -= _value;
        
        // Emit transfer event
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    // ===========================================
    // HELPER FUNCTIONS
    // ===========================================
    
    /**
     * @notice Get the token balance of an address
     * @dev This is a view function (doesn't cost gas when called externally)
     * @param _owner The address to check
     * @return balance The token balance in base units
     */
    function getBalance(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }
    
    /**
     * @notice Get the remaining allowance for a spender
     * @param _owner The address that owns the tokens
     * @param _spender The address allowed to spend
     * @return remaining The remaining allowance in base units
     */
    function getAllowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }
}