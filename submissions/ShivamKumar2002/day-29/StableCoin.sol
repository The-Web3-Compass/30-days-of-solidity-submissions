// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title StableCoin
 * @author shivam
 * @notice A basic ERC20 token contract (LDOLLAR) with minting and burning capabilities restricted to a designated PegManager.
 * @dev Implements core ERC20 functionalities manually without external libraries.
 */
contract StableCoin {
    /// @notice The name of the token
    string public constant name = "LDOLLAR";
    /// @notice The symbol of the token
    string public constant symbol = "LDOLLAR";
    /// @notice The number of decimal places the token uses
    uint8 public constant decimals = 18; // Standard decimal places for ERC20
    /// @notice The total supply of the token
    uint256 public totalSupply;

    /// @notice Mapping from account addresses to their token balances
    mapping(address => uint256) public balanceOf;
    /// @notice Mapping from owner addresses to spender addresses to the amount they are allowed to spend
    mapping(address => mapping(address => uint256)) public allowance;

    /// @notice The address of the contract owner
    address public owner;
    /// @notice The address of the designated PegManager contract
    address public pegManager;

    /// @notice Emitted when tokens are moved from one account to another
    /// @param from The address of the sender
    /// @param to The address of the receiver
    /// @param value The amount of tokens transferred
    event Transfer(address indexed from, address indexed to, uint256 value);
    /// @notice Emitted when the allowance of a spender for an owner is set
    /// @param owner The address of the token owner
    /// @param spender The address of the approved spender
    /// @param value The amount of tokens the spender is approved to spend
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @dev Modifier to restrict function calls to the contract owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "StableCoin: Caller is not the owner");
        _;
    }

    /// @dev Modifier to restrict function calls to the designated PegManager contract.
    modifier onlyPegManager() {
        require(msg.sender == pegManager, "StableCoin: Caller is not the PegManager");
        _;
    }

    /**
     * @notice Initializes the contract and sets the deployer as the owner.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Sets the address of the PegManager contract.
     * @dev Can only be called by the owner.
     * @param _pegManager The address of the PegManager contract.
     */
    function setPegManager(address _pegManager) external onlyOwner {
        require(_pegManager != address(0), "StableCoin: Invalid PegManager address");
        pegManager = _pegManager;
    }

    /**
     * @notice Transfers tokens from the caller's account to another account.
     * @param to The address of the recipient.
     * @param value The amount of tokens to transfer.
     * @return A boolean indicating if the transfer was successful.
     */
    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "StableCoin: Transfer to the zero address");
        require(balanceOf[msg.sender] >= value, "StableCoin: Transfer amount exceeds balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @notice Approves a spender to spend a specified amount of tokens on behalf of the caller.
     * @param spender The address of the account to be approved.
     * @param value The maximum amount of tokens the spender can spend.
     * @return A boolean indicating if the approval was successful.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0), "StableCoin: Approve to the zero address");
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @notice Transfers tokens from one account to another using the allowance mechanism.
     * @dev The caller must be approved to spend `value` tokens from the `from` account.
     * @param from The address of the sender.
     * @param to The address of the recipient.
     * @param value The amount of tokens to transfer.
     * @return A boolean indicating if the transfer was successful.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(from != address(0), "StableCoin: Transfer from the zero address");
        require(to != address(0), "StableCoin: Transfer to the zero address");
        require(balanceOf[from] >= value, "StableCoin: Transfer amount exceeds balance");
        require(allowance[from][msg.sender] >= value, "StableCoin: Transfer amount exceeds allowance");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    /**
     * @notice Mints new tokens and assigns them to an account.
     * @dev Can only be called by the designated PegManager contract.
     * @param to The address of the account to receive the minted tokens.
     * @param value The amount of tokens to mint.
     */
    function mint(address to, uint256 value) external onlyPegManager {
        require(to != address(0), "StableCoin: Mint to the zero address");
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    /**
     * @notice Burns tokens from an account.
     * @dev Can only be called by the designated PegManager contract.
     * @param from The address of the account to burn tokens from.
     * @param value The amount of tokens to burn.
     */
    function burn(address from, uint256 value) external onlyPegManager {
        require(from != address(0), "StableCoin: Burn from the zero address");
        require(balanceOf[from] >= value, "StableCoin: Burn amount exceeds balance");

        totalSupply -= value;
        balanceOf[from] -= value;
        emit Transfer(from, address(0), value);
    }
}