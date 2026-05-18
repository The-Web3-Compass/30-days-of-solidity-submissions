// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

/**
 * @title TipJar
 * @dev Build a multi-currency digital tip jar!
 * Users can send Ether directly or simulate tips in foreign currencies like USD or EUR.
 * You'll learn how to manage currency conversion, handle Ether payments using `payable` and `msg.value`,
 * and keep track of individual contributions.
 * Think of it like an advanced version of a 'Buy Me a Coffee' button — but smarter, more global, and Solidity-powered.
 * implementation of https://www.web3compass.xyz/challenge-calendar day 8
 */
contract TipJar {
    address public manager;
    uint256 public totalTips = 0;
    mapping(string => uint256) public exchangeRates;

    constructor() {
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "only manager is allowed to perform this action");
        _;
    }

    function updateExchangeRate(string memory currency, uint256 rate) public onlyManager {
        exchangeRates[currency] = rate;
    }

    //  convenience function for testing only
    function setDefaultExchangeRates() public onlyManager {
        updateExchangeRate("EUR", 6000);
        updateExchangeRate("USD", 5000);
        updateExchangeRate("SGD", 4000);
    }

    function convertWithExchangeRate(string memory currency, uint256 amount) public view returns(uint256 convertedAmount) {
        require(exchangeRates[currency] > 0, "currency does not have any exchange rate set");
        convertedAmount = exchangeRates[currency] * amount;
    }

    function addTip(string memory currency, uint256 amount) public payable {
        require(amount > 0, "tip must be non-zero");
        uint256 convertedAmount = convertWithExchangeRate(currency, amount);
        require(convertedAmount == msg.value, "tip amount does not match exchange rate connversion");
        totalTips += msg.value;
    }

    function withdrawAllTips() public onlyManager {
        uint256 currentTips = address(this).balance;
        require(currentTips > 0, "nothing to withdraw");
        // payable(manager).transfer(currentTips); // more risky way to transfer
        (bool transferWorked,) = payable(manager).call{ value: currentTips }("");
        require(transferWorked, "transfer failed");
    }
}
