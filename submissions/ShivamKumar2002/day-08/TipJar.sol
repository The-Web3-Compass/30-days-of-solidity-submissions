// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TipJar
 * @author shivam
 * @notice A simple contract to simulate a virtual tip jar with currency conversion.
     How it works:
     - The owner of contract is the person who will receive tips.
     - Users can give virtual tips in their desired currency.
     - Owner can set exchange rates (currency to wei) for different currencies that are accepted.
     - Currencies for which exchange rates are not set will be rejected.
 */
contract TipJar {
    /// @notice eth address of contract owner
    address public owner;

    /// @notice Total tip amount collected (in wei)
    uint private totalTip;

    /// @notice Mapping of currency name to wei exchange rates.
    mapping(string => uint) public exchangeRates;

    /// @notice Event emitted when conversion rate of a currency is updated.
    /// @param currency Currency name
    /// @param oldRate Old conversion rate
    /// @param newRate Updated conversion rate
    event ConversionRateChanged(string indexed currency, uint oldRate, uint newRate);

    /// @notice Event emitted when a new tip is received.
    /// @param sender Tip sender.
    /// @param amount Tip amount converted to wei.
    event NewTip(address indexed sender, uint amount);

    /// @notice Error thrown when an action is not allowed.
    error NotAllowed();

    /// @notice Error thrown when given currency is not allowed.
    error CurrencyNotAllowed();

    /// @notice Initializes the contract by setting owner address and initial conversion rates.
    constructor() {
        owner = msg.sender;

        // dummy exchange rates
        exchangeRates["USD"] = 51000;
        exchangeRates["EUR"] = 53000;
        exchangeRates["INR"] = 600;
    }

    /// @notice Ensures that caller is owner of the contract.
    /// @custom:error NotAllowed if caller is not the owner.
    modifier ownerOnly() {
        if (msg.sender != owner) {
            revert NotAllowed();
        }
        _;
    }

    /// @notice Get total tip amount received. Only contract owner can access it.
    function getTotalTip() external view ownerOnly returns (uint) {
        return totalTip;
    }
    
    /// @notice Sets exchange rates for a currency. If rate is set to zero, the currency will be rejected.
    /// @param _currency Currency name.
    /// @param _rate Currency to wei exchange rate.
    /// @dev Only owner can set exchange rate.
    function setExchangeRate(string memory _currency, uint _rate) external ownerOnly {
        uint oldRate = exchangeRates[_currency];
        exchangeRates[_currency] = _rate;
        emit ConversionRateChanged(_currency, oldRate, _rate);
    }

    /// @notice Tip given amount in given currency to owner of contract.
    /// @param _amount Tip amount in sender's currency.
    /// @param _currency Sender's currency name.
    /// @custom:error CurrencyNotAllowed if sender's currency is not allowed.
    function tip(uint _amount, string memory _currency) external {
        require (_amount > 0, "amount must be greater than 0.");
        if (exchangeRates[_currency] == 0) {
            revert CurrencyNotAllowed();
        }
        uint weiAmount = _amount * exchangeRates[_currency];
        totalTip += weiAmount;
        emit NewTip(msg.sender, weiAmount);
    }

}