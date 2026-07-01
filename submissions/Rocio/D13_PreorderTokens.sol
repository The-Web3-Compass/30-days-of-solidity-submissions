// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title TokenSale
 * @dev Simple contract to sell a specific ERC-20 token for a fixed amount of Ether.
 * The contract owner is responsible for funding the contract with the tokens
 * to be sold.
 */
contract TokenSale is Ownable {
    using SafeMath for uint256;

    // The ERC20 token being sold
    IERC20 public immutable token;
    
    // The price: how many tokens a buyer gets for 1 Ether (in WADs, 1e18)
    uint256 public rate; 
    
    // The address where collected Ether will be sent
    address payable public wallet; 

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @notice Initializes the contract.
     * @param _rate The token exchange rate (tokens per Ether). e.g., 1000 for 1 Ether.
     * @param _wallet The address to hold and manage the collected Ether.
     * @param _token The address of the ERC20 token contract.
     */
    constructor(uint256 _rate, address payable _wallet, IERC20 _token) Ownable(msg.sender) {
        require(_rate > 0, "TokenSale: Rate must be greater than zero");
        require(_wallet != address(0), "TokenSale: Wallet cannot be the zero address");
        require(address(_token) != address(0), "TokenSale: Token address cannot be zero");

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

    /**
     * @notice Allows buyers to purchase tokens by sending Ether to this function.
     * @dev The function uses `msg.sender` as the beneficiary.
     */
    receive() external payable {
        buyTokens(msg.sender);
    }

    /**
     * @notice Logic for buying tokens.
     * @param _beneficiary The address that will receive the purchased tokens.
     */
    function buyTokens(address _beneficiary) public payable {
        // 1. Basic checks
        uint256 weiAmount = msg.value;
        require(weiAmount > 0, "TokenSale: Ether amount must be greater than zero");
        require(_beneficiary != address(0), "TokenSale: Beneficiary cannot be the zero address");

        // 2. Calculation
        // amount = weiAmount * rate / 1e18 (since rate is usually in base units)
        uint256 tokensAmount = weiAmount.mul(rate).div(1 ether); 
        
        require(tokensAmount > 0, "TokenSale: Tokens amount must be greater than zero");

        // 3. Token availability check
        // Check if the contract has enough tokens to fulfill the request
        uint256 currentBalance = token.balanceOf(address(this));
        require(currentBalance >= tokensAmount, "TokenSale: Not enough tokens available for sale");

        // 4. Execution (Transfer Ether and Tokens)
        // Send the collected Ether to the designated wallet
        (bool success, ) = wallet.call{value: weiAmount}("");
        require(success, "TokenSale: Ether transfer failed");
        
        // Transfer the tokens to the buyer
        bool tokenSuccess = token.transfer(_beneficiary, tokensAmount);
        require(tokenSuccess, "TokenSale: Token transfer failed");

        // 5. Emit event
        emit TokensPurchased(msg.sender, _beneficiary, weiAmount, tokensAmount);
    }

    // --- OWNER FUNCTIONS ---

    /**
     * @notice Allows the owner to withdraw any remaining tokens not sold.
     * @dev Should only be called after the sale period is over.
     */
    function withdrawUnsoldTokens() external onlyOwner {
        uint256 unsoldTokens = token.balanceOf(address(this));
        require(unsoldTokens > 0, "TokenSale: No tokens to withdraw");
        
        bool success = token.transfer(owner(), unsoldTokens);
        require(success, "TokenSale: Token withdrawal failed");
    }

    /**
     * @notice Allows the owner to update the token exchange rate.
     */
    function setRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "TokenSale: Rate must be greater than zero");
        rate = newRate;
    }
}