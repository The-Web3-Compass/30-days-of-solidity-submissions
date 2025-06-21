// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract TipJar {
    error ConversionRate__CannotBeZero();
    error Unsupported__Currency();
    error Invalid__AmountCannotBeZero();

    address public owner;
    string[] public CurrenciesWeAccept;

    mapping(string => uint256) public conversationRate;
    uint256 public totalTips;
    mapping(address => uint256) public tipsReceived;
    mapping(string => uint256) public tipsPerCurrency;

    constructor() {
        owner = msg.sender;
        addCurrency("USD", (5 * 10) ** 14); // 1 USD = 0.0000000000005 ETH
        addCurrency("EUR", (6 * 10) ** 14); // 1 EUR = 0.0000000000006 ETH
        addCurrency("GBP", (7 * 10) ** 14); // 1 GBP = 0.0000000000007 ETH
        addCurrency("INR", (8 * 10) ** 14); // 1 INR = 0.0000000000008 ETH
    }

    modifier OnlyOwner() {
        require(msg.sender == owner, "Sorry you are not the owner");
        _;
    }

    function addCurrency(
        string memory _currencyCode,
        uint256 _conversionRate
    ) public OnlyOwner {
        if (_conversionRate == 0) {
            revert ConversionRate__CannotBeZero();
        }

        bool currencyExists = false;
        for (uint256 i = 0; i < CurrenciesWeAccept.length; i++) {
            if (
                keccak256(abi.encodePacked(CurrenciesWeAccept[i])) ==
                keccak256(abi.encodePacked(_currencyCode))
            ) {
                currencyExists = true;
                break;
            }
        }
        if (!currencyExists) {
            CurrenciesWeAccept.push(_currencyCode);
        }
        conversationRate[_currencyCode] = _conversionRate;
    }

    function convertToETH(
        string memory _currencyCode,
        uint256 _amount
    ) public view returns (uint256) {
        if (conversationRate[_currencyCode] == 0) {
            revert Unsupported__Currency();
        }

        uint256 covertToEth = (_amount * conversationRate[_currencyCode]) /
            (10 ** 18);
        return covertToEth;
    }

    function ETHtip() public payable {
        if (msg.value == 0) {
            revert Invalid__AmountCannotBeZero();
        }
        tipsReceived[msg.sender] += msg.value;

        totalTips += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }

    function CurrencyTip(
        string memory _currencyCode,
        uint256 _amount
    ) public payable {
        if (conversationRate[_currencyCode] == 0) {
            revert Unsupported__Currency();
        }
        if (_amount == 0) {
            revert Invalid__AmountCannotBeZero();
        }

        uint256 getConvertedAmount = convertToETH(_currencyCode, _amount);

        if (msg.value != getConvertedAmount) {
            revert("Amount sent does not match the converted amount");
        }

        tipsReceived[msg.sender] += msg.value;

        totalTips += msg.value;
        tipsPerCurrency[_currencyCode] += msg.value;
    }

    function Withdraw() public OnlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert Invalid__AmountCannotBeZero();
        }
        (bool success, ) = payable(owner).call{value: balance}("");
        if (!success) {
            revert("Withdrawal failed");
        }
        totalTips = 0;
    }
}
