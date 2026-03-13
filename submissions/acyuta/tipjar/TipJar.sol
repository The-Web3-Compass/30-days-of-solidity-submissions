// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
    function getPrice() internal view returns (uint256) {
        // address 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // abi
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // Price of eth in terms of USD
        // 2000.00000000
        return uint256(price * 1e10);
    }
    function getConversionRate(uint256 ethAmount) internal view returns(uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    function getVersion() internal view returns (uint256) {
        return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
    }
}

contract TipJar {
    event TipReceived(address indexed tipper, uint amount);
    event AmountWithdrawn(uint amount);

    error TipJar__NotEnoughTips();
    error TipJar__TransactionFailed();
    error TipJar__OwnerOnly();

    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 1e18; //constant takes less gas

    address[] public funders;

    address private immutable i_owner;
    mapping(address => uint) patrons;
    uint private tips;

    modifier ownerOnly() {
        if (msg.sender != i_owner) revert TipJar__OwnerOnly();
        _;
    }

    constructor() {
        i_owner = msg.sender;
    }

    function tipJarInCurrency() public payable {
        require(
            msg.value.getConversionRate() >= MINIMUM_USD,
            "didn't send enough ETH"
        );
        // 1e18 = 1 ETH = 1 * 10 ** 18
        funders.push(msg.sender);
        patrons[msg.sender] += msg.value;
        tips += msg.value;

        emit TipReceived(msg.sender, msg.value);
    }   

    function tipJarInEth() public payable {
        patrons[msg.sender] += msg.value;
        tips += msg.value;

        emit TipReceived(msg.sender, msg.value);
    }

    function withDrawTips(uint _amount) public ownerOnly {
        if (_amount > tips) revert TipJar__NotEnoughTips();
        tips -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        if (!success) revert TipJar__TransactionFailed();

        emit AmountWithdrawn(_amount);
    }


    function getBalance() public view ownerOnly returns (uint) {
        return address(this).balance;
    }

    function resetPatronsList() public {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            patrons[funder] = 0;
        }

        // reset the array
        funders = new address[](0);
    }

    receive() external payable {
        tipJarInCurrency();
    }

    fallback() external payable {
        tipJarInCurrency();
    }
}
