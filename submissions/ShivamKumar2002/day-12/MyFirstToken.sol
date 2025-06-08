// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MyFirstToken
 * @author shivam
 * @notice A simple ERC20 token implemented by following official spec: https://eips.ethereum.org/EIPS/eip-20
 */
contract MyFirstToken {
    /// @notice Name of token
    string public constant name = "My First Token";
    /// @notice Symbol of token
    string public constant symbol = "MYFT";
    /// @notice Number of decimals used by token
    uint8 public constant decimals = 5;
    
    /// @notice Max number of tokens in existence
    uint256 public totalSupply;

    /// @notice Balances of users
    mapping(address => uint256) private balances;

    /// @notice Mapping of owner address to mapping of spender address to approved spending amount
    /// @dev approved[owner][spender] = amount
    mapping(address => mapping(address=>uint256)) private approved;

    /// @notice Event emitted when tokens are transferred, including zero value transfers
    /// @param _from Sender address (0x0 when tokens are created)
    /// @param _to Receiver address
    /// @param _value Amount transferred
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// @notice Event emitted on any successful call to approve
    /// @param _owner Balance owner
    /// @param _spender Approved spender
    /// @param _value Amount approved for spending
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// @notice Initializes the contract by giving total supply to contract owner
    /// @param _initialSupply Initial total supply of token
    constructor(uint256 _initialSupply) {
        require(_initialSupply > 0, "Initial supply must be positive");
        totalSupply = _initialSupply;

        // give all balance to contract owner
        balances[msg.sender] = totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    /// @notice Get balance of address
    /// @param _owner Address to get balance for
    /// @return balance Balance of address
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /// @notice Get the amount of tokens which a user is approved to use from balance of another user
    /// @param _owner Address which owns the balance
    /// @param _spender Address which is approved to use the balance
    /// @return remaining Amount tokens approved to use
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return approved[_owner][_spender];
    }

    /// @notice Transfer token from caller's address to another address
    /// @param _to Receiver address
    /// @param _value Amount to transfer
    /// @return success Whether the transfer was successful
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "address must not be zero");
        require(_value <= balances[msg.sender], "insufficient funds");
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice Transfers token from one address to another. Caller must be approved to spend.
    /// @param _from Address of sender
    /// @param _to Address of receiver
    /// @param _value Amount of tokens to transfer
    /// @return success Whether the transfer was successful
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0), "from address must not be zero");
        require(_to != address(0), "to address must not be zero");
        require(_value <= balances[_from], "insufficient funds");
        require(_value <= approved[_from][msg.sender], "insufficient approved tokens");

        approved[_from][msg.sender] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @notice Approve another address to use the specified amount of tokens from account of caller, overriding existing approved amount.
    /// @param _spender Address to approve
    /// @param _value Amount of tokens to approve
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "spender address must not be zero");

        approved[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}