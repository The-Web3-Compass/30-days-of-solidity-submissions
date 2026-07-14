//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {conversionRates} from "./conversionRates.sol";

contract TipJar is conversionRates{

 // ----------------Variables----------------

    address public owner; // the owner of the TipJar
    string[] public supportedCurrencies;
    uint256 public totalTipsReceieved;
    mapping(address => uint256) public tipsPerPerson;
    mapping(string =>uint256) public tipsPerCurrency;
    
// ----------------Constructor----------------
 constructor() {
    owner =  msg.sender;
    
 }

// ----------------Modifier----------------

modifier onlyOwner() {
    require(owner == msg.sender, "you are not the owner");
_;
}

// ----------------functions----------------
function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
    require(_rateToEth > 0, "Conversion rate must be greater than 0");

    bool currencyExists = false;
    for (uint i = 0; i < supportedCurrencies.length; i++) {
        if (keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))) {
            currencyExists = true;
            break;
        }
    }

    if (!currencyExists) {
        supportedCurrencies.push(_currencyCode);
    }
}
  
  function tipInEth() payable public {
    require(msg.value >0, "you don't enough eth to tip");


    tipsPerPerson[msg.sender] += msg.value;
    totalTipsReceieved += msg.value;
    tipsPerCurrency["ETH"] += msg.value;
  }

  function tipInBTC() payable public {
    require(msg.value>0, "you don't enough BTC to tip" );
    tipsPerPerson[msg.sender] += msg.value;
    tipsPerCurrency["BTC"] += msg.value;
    totalTipsReceieved += msg.value;
  }


    function withdrawTips() public onlyOwner {
        uint contractBalance = address(this).balance;
        require(contractBalance > 0, "No tips to withdraw");

        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Transfer failed");

        totalTipsReceieved = 0;
    }


    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getTipperContribution(address _tipper) public view returns (uint256) {
        return tipsPerPerson[_tipper];
    }

    function getTipsPerCurrency(string memory _currencyCode) public view returns(uint256) {
        return tipsPerCurrency[_currencyCode];
        }
        // 1000000000000000000
  }