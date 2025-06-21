// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC20 Minimal Interface
 * @dev Interface for required ERC20 functions for token sale
 */
interface IERC20 {
    /// @notice Get balance of address
    /// @param _owner Address to get balance for
    /// @return balance Balance of address
    function balanceOf(address _owner) external view returns (uint256 balance);
    
    /// @notice Transfer tokens from caller's address to another address
    /// @param to Receiver address
    /// @param amount Amount to transfer
    /// @return success Whether the transfer was successful
    function transfer(address to, uint256 amount) external returns (bool);
}


/**
 * @title TokenSale
 * @author shivam
 * @notice A contract to sell MyFirstToken (MYFT) for ETH
 */
contract TokenSale {
    /// @notice Address of TokenSale contract owner
    address public owner;
    /// @notice Instance of ERC20 token being sold (MYFT)
    IERC20 public token;
    /// @notice price of 1 token unit in wei
    /// @dev token unit is 1 / decimals of token
    uint256 public tokenPriceInWei;
    /// @notice total number of token units sold
    uint256 public tokensSold;

    /// @notice Event emitted when tokens are purchased
    /// @param buyer Address of the buyer
    /// @param amount Amount of ETH (in Wei) spent
    /// @param tokens Amount of token units purchased
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 tokens);

    /// @notice Event emitted when the owner withdraws ETH
    /// @param owner Address of the owner
    /// @param amount Amount of Ether (in Wei) withdrawn
    event EthWithdrawn(address indexed owner, uint256 amount);

    /// @notice Error thrown when an action is not allowed.
    error NotAllowed();

    /// @notice Error thrown when amount sent is too low to buy any tokens
    /// @param minAmount Minimum amount to buy a token unit
    error AmountTooLow(uint256 minAmount);

    /// @notice Error thrown when TokenSale contract doesn't have enough tokens balance
    /// @param availableTokens Number of tokens available currently
    error InsufficientTokens(uint256 availableTokens);

    /// @notice Ensures that caller is owner of the contract
    /// @custom:error NotAllowed if caller is not the owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotAllowed();
        }
        _;
    }

    /// @notice Initializes the contract by setting owner, token instance and price
    /// @param _tokenContractAddress The address of the deployed MyFirstToken contract.
    /// @param _tokenPriceInWei The price of one token in Wei.
    constructor(address _tokenContractAddress, uint256 _tokenPriceInWei) {
        require(_tokenContractAddress != address(0), "TokenSale: Token address cannot be zero");
        require(_tokenPriceInWei > 0, "TokenSale: Token price must be greater than 0");

        owner = msg.sender;
        token = IERC20(_tokenContractAddress);
        tokenPriceInWei = _tokenPriceInWei;
    }

    /// @notice Allows the contract to receive ETH directly
    /// Redirects the ETH to the buyTokens function
    receive() external payable {
        buyTokens();
    }

    /// @notice Get the number of tokens available for sale
    /// @return tokens Token balance of this contract
    function availableTokens() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /// @notice Allows users to buy tokens by sending ETH
    function buyTokens() public payable {
        require(msg.value > 0, "TokenSale: Send ETH to buy tokens");

        // calculate number of tokens
        uint256 tokens = msg.value / tokenPriceInWei;
        if (tokens <= 0) {
            revert AmountTooLow(tokenPriceInWei);
        }

        // Check if the contract has enough tokens
        uint256 contractTokens = token.balanceOf(address(this));
        if (contractTokens < tokens) {
            revert InsufficientTokens(contractTokens);
        }

        tokensSold += tokens;

        // Transfer the tokens from this contract to the buyer (msg.sender)
        bool sent = token.transfer(msg.sender, tokens);
        require(sent, "TokenSale: Token transfer failed");

        emit TokensPurchased(msg.sender, msg.value, tokens);
    }

    /// @notice Allows the owner to withdraw the accumulated ETH from the contract
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "TokenSale: No ETH to withdraw");

        // Transfer the Ether to the owner
        (bool success, ) = owner.call{value: balance}("");
        require(success, "TokenSale: Ether withdrawal failed");

        emit EthWithdrawn(owner, balance);
    }
}