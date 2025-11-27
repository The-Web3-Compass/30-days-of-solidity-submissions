// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TipJar{ 
    address public owner;

    string[] currencies;

    mapping(string => uint) public tips;
    mapping(string => uint) public rates;
    mapping(address => uint) public tippers;

    uint256 total;
    
    modifier onlyOwner(){
        require (msg.sender == owner, "You are not authorized!");
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public{
        require (newOwner != address(0), "Invalid address");

        owner = newOwner;
    }

    function addCurrency(string memory _currency, uint _rate) public onlyOwner{
        require (_rate > 0, "Must be above 0");

        bool exists = false;
        for (uint256 i = 0; i < currencies.length; i++) {
            if (keccak256(bytes(currencies[i])) == keccak256(bytes(_currency))) {
                exists = true;
                break;
            }
        }

        if (!exists) {
            currencies.push(_currency);
            rates[_currency] = _rate;
        }

    }

    constructor() {
        owner = msg.sender;

        addCurrency("USD", 9 * 10**14);
        addCurrency("EUR", 8 * 10**14);
        addCurrency("JPY", 4 * 10**12);
        addCurrency("GBP", 7 * 10**14);
    }


    function convertETH(string memory _currency, uint256 _tip) public view returns(uint256){
        require (_tip > 0, "Must be above 0");

        uint256 ethValue = _tip * rates[_currency];

        return ethValue;
    }

    function ethTip() public payable{
        require (msg.value > 0, "Must be above 0");

        tips["ETH"] += msg.value;
        tippers[msg.sender] += msg.value;
        total += msg.value;
    }

    function currencyTip(string memory _currency, uint256 _tip) public {
        require (_tip > 0, "must be above 0");

        uint256 ethValue = convertETH(_currency, _tip);
        tips[_currency] += _tip;
        tippers[msg.sender] = ethValue;
        total += ethValue;
    }

    function getCurrencies() public view returns (string[] memory){
        return currencies;
    }

    function withdrawTips(address payable user, uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient funds");
        require(user != address(0), "Enter a valid address");

        (bool success, ) = user.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    function getTippers(address _tipper) public view returns (uint256) {
        return tippers[_tipper];
    }


    function getBalance() public view returns (uint256){
        return address(this).balance;
    }

}