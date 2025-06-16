// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleToken
 * @author shivam
 * @dev A basic implementation of an ERC20-like token.
 */
contract SimpleToken {
    // --- State Variables ---

    /// @notice The name of the token.
    string public name;
    /// @notice The symbol of the token.
    string public symbol;
    /// @notice The number of decimals the token uses.
    uint8 public constant decimals = 18;
    /// @notice The total supply of the token.
    uint256 public totalSupply;

    /// @notice Mapping from account address to token balance.
    mapping(address => uint256) public balanceOf;
    /// @notice Mapping from owner address to spender address to allowance amount.
    mapping(address => mapping(address => uint256)) public allowance;

    // --- Events ---

    /// @notice Emitted when tokens are transferred from one account to another.
    /// @param from The address sending tokens (zero address for minting).
    /// @param to The address receiving tokens.
    /// @param value The amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Emitted when an allowance is set by an owner for a spender.
    /// @param owner The address granting the allowance.
    /// @param spender The address receiving the allowance.
    /// @param value The amount of tokens approved.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // --- Constructor ---

    /**
     * @notice Sets the name and symbol for the token upon deployment.
     * @param _name The desired name for the token.
     * @param _symbol The desired symbol for the token.
     */
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    // --- Functions ---

    /**
     * @notice Transfers tokens from the caller's account to a recipient.
     * @dev Emits a {Transfer} event.
     * @param _to The address of the recipient.
     * @param _value The amount of tokens to transfer.
     * @return success True if the transfer was successful, false otherwise.
     */
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0), "SimpleToken: transfer to the zero address");
        uint256 senderBalance = balanceOf[msg.sender];
        require(senderBalance >= _value, "SimpleToken: transfer amount exceeds balance");

        balanceOf[msg.sender] = senderBalance - _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @notice Approves a spender to withdraw tokens from the caller's account.
     * @dev Emits an {Approval} event. Overwrites any previous allowance.
     * @param _spender The address authorized to spend the tokens.
     * @param _value The maximum amount of tokens the spender is allowed to withdraw.
     * @return success True if the approval was successful.
     */
    function approve(address _spender, uint256 _value) external returns (bool success) {
        require(_spender != address(0), "SimpleToken: approve to the zero address");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @notice Transfers tokens from one account to another using the allowance mechanism.
     * @dev The caller must have been approved by the `_from` account.
     * Emits a {Transfer} event.
     * @param _from The address sending the tokens.
     * @param _to The address receiving the tokens.
     * @param _value The amount of tokens to transfer.
     * @return success True if the transfer was successful.
     */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_from != address(0), "SimpleToken: transfer from the zero address");
        require(_to != address(0), "SimpleToken: transfer to the zero address");
        require(balanceOf[_from] >= _value, "SimpleToken: transfer amount exceeds balance");

        uint256 currentAllowance = allowance[_from][msg.sender];
        require(currentAllowance >= _value, "SimpleToken: transfer amount exceeds allowance");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] = currentAllowance - _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @notice Mints new tokens and assigns them to an account.
     * @dev Increases the total supply. Emits a {Transfer} event with `from` set to the zero address.
     * This is a public function for testing/educational purposes.
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) external {
        require(_to != address(0), "SimpleToken: mint to the zero address");
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
    }
}