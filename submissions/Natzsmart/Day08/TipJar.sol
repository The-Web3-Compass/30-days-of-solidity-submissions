// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

/*
 * @title TipJar
 * @notice A contract that accepts tips in Ether and various supported currencies.
 * It manages conversion rates, tracks individual contributions, and allows the owner to withdraw tips.
 */
contract TipJar {
    // The owner of the contract (typically the deployer) who can manage settings and withdraw tips.
    address public owner;
    
    // Total amount of Ether tips received (in wei).
    uint256 public totalTipsReceived;
    
    /*
     * @notice Conversion rates from different currencies to Ether.
     * For example, if 1 USD = 0.0005 ETH, then the rate would be 5 * 10^14 (assuming rate is scaled).
     */
    mapping(string => uint256) public conversionRates;

    // Mapping to track the total tip amount given by each address (in wei).
    mapping(address => uint256) public tipPerPerson;
    
    // Array to store a list of all supported currency codes.
    string[] public supportedCurrencies;
    
    // Mapping to track the total tips received for each currency.
    // For ETH, tips are counted in wei; for others, in the unit specified.
    mapping(string => uint256) public tipsPerCurrency;
    
    /*
     * @notice Constructor initializes the contract by setting the deployer as the owner.
     * It also adds some default supported currencies with their conversion rates.
     */
    constructor() {
        owner = msg.sender;
        // Add default currencies and their conversion rates.
        addCurrency("USD", 5 * 10**14);  // 1 USD = 0.0005 ETH
        addCurrency("EUR", 6 * 10**14);  // 1 EUR = 0.0006 ETH
        addCurrency("JPY", 4 * 10**12);  // 1 JPY = 0.000004 ETH
        addCurrency("INR", 7 * 10**12);  // 1 INR = 0.000007 ETH
    }
    
    /*
     * @dev Modifier to restrict actions to only the owner of the contract.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    /*
     * @notice Adds or updates a supported currency along with its conversion rate to ETH.
     * @param _currencyCode The three-letter currency code, e.g., "USD" or "EUR".
     * @param _rateToEth The conversion rate (scaled) from the currency to Ether.
     * Requirements:
     * - The conversion rate must be greater than 0.
     */
    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Conversion rate must be greater than 0");
        bool currencyExists = false;
        // Check if the currency is already supported.
        for (uint i = 0; i < supportedCurrencies.length; i++) {
            if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))) {
                currencyExists = true;
                break;
            }
        }
        // If the currency is not already supported, add it to the list.
        if (!currencyExists) {
            supportedCurrencies.push(_currencyCode);
        }
        // Set or update the conversion rate.
        conversionRates[_currencyCode] = _rateToEth;
    }
    
    /*
     * @notice Converts a given amount in a specified currency to its Ether equivalent.
     * @param _currencyCode The code of the currency to convert.
     * @param _amount The amount in that currency.
     * @return ethAmount The equivalent amount in Ether (in wei).
     * Requirements:
     * - The currency must be supported (conversion rate > 0).
     */
    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        uint256 ethAmount = _amount * conversionRates[_currencyCode];
        return ethAmount;
        // Note: For a human-readable amount (in ETH), consider dividing the result by 10^18.
    }
    
    /*
     * @notice Allows anyone to send a tip in Ether directly.
     * The sent value is added to the sender's tip record, total tips, and recorded as an ETH tip.
     */
    function tipInEth() public payable {
        require(msg.value > 0, "Tip amount must be greater than 0");
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }
    
    /*
     * @notice Allows users to tip using a supported currency. The correct Ether amount must be sent.
     * @param _currencyCode The code of the currency for the tip.
     * @param _amount The amount in the selected currency.
     * Requirements:
     * - The currency must be supported.
     * - The sent Ether must exactly equal the converted amount.
     */
    function tipInCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        require(_amount > 0, "Amount must be greater than 0");
        uint256 ethAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == ethAmount, "Sent ETH doesn't match the converted amount");
        tipPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += _amount;
    }

    /*
     * @notice Allows the owner to withdraw all Ether from the contract.
     * After withdrawal, totalTipsReceived is reset to 0.
     * Requirements:
     * - There must be a positive balance in the contract.
     */
    function withdrawTips() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer failed");
        totalTipsReceived = 0;
    }
  
    /*
     * @notice Allows the current owner to transfer contract ownership to a new owner.
     * @param _newOwner The address of the new owner.
     * Requirements:
     * - The new owner's address must be valid (non-zero).
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }

    /*
     * @notice Returns the list of supported currency codes.
     * @return An array of currency codes.
     */
    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }
    
    /*
     * @notice Retrieves the current Ether balance of the contract.
     * @return The contract's balance in wei.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    /*
     * @notice Returns the total tip contribution made by a specific address.
     * @param _tipper The address of the tipper.
     * @return The tip amount in wei contributed by the given address.
     */
    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipPerPerson[_tipper];
    }
    
    /*
     * @notice Retrieves the total tips recorded for a specific currency.
     * @param _currencyCode The currency code to check.
     * @return The total amount of tips recorded in the specified currency.
     */
    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }

    /*
     * @notice Returns the conversion rate from a given currency to Ether.
     * @param _currencyCode The currency code to check.
     * @return The conversion rate for the given currency.
     * Requirements:
     * - The currency must be supported.
     */
    function getConversionRate(string memory _currencyCode) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency not supported");
        return conversionRates[_currencyCode];
    }
}