//SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

contract TipJar {
    address public owner;
    string[] public supportedCurrencies;
    mapping (string => uint256) conversionRates;
    uint256 public totalTipsReceived;
    mapping(address => uint256) tipsPerPerson;
    mapping(string => uint256) tipsPerCurrency;

    modifier onlyOwner() {
        require(msg.sender == owner,"Access denied: Only owner has the permission to access.");
        _;
    }

    constructor() {
        owner = msg.sender;
        addCurrency("USD",4*10**14); // 1 USD = 0.0004 ETH
        addCurrency("GBP",5*10**14); // 1 GBP = 0.0005ETH
        addCurrency("CNY",6*10**13); // 1 CNY = 0.00006ETH
        addCurrency("HKD",5*10**13); //1 HKD = 0.00005ETH
    }

    function addCurrency(string memory _currencyCode, uint256 _rateToEth) public onlyOwner {
        require(_rateToEth > 0, "Conversion rate should be greater than 0.");
        bool currencyExists = false;
        for (uint256 i = 0; i < supportedCurrencies.length; i++) {
            if(keccak256(bytes(supportedCurrencies[i])) == keccak256(bytes(_currencyCode))){
                currencyExists = true;
                break;
            }
        }
        if (currencyExists = false) {
            supportedCurrencies.push(_currencyCode);
        }
        conversionRates[_currencyCode] = _rateToEth;
    }

    function convertToEth(string memory _currencyCode, uint256 _amount) public view returns (uint256) {
        require(conversionRates[_currencyCode] > 0, "Currency is not supported.");
        uint256 weiAmount = _amount * conversionRates[_currencyCode];
        return weiAmount; // in front end should divide by 10**18
    }

    function tipEth() public payable {
        require(msg.value > 0, "You must give us some ETH.");
        tipsPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency["ETH"] += msg.value;
    }

    function tipCurrency(string memory _currencyCode, uint256 _amount) public payable {
        require(conversionRates[_currencyCode] > 0, "Currency is not supported.");
        require(msg.value > 0, "You must giev some currency.");
        uint256 weiAmount = convertToEth(_currencyCode, _amount);
        require(msg.value == weiAmount, "sent ETH doesn't match the converted amount.");
        tipsPerPerson[msg.sender] += msg.value;
        totalTipsReceived += msg.value;
        tipsPerCurrency[_currencyCode] += msg.value;
    }

    function withdralTips() public onlyOwner {
        uint256 contractBalance = address(this).balance; 
        // this -> the current contract ETH address; contractBalance will retreive the current ETH balance
        require(contractBalance > 0, "Please input a number greater than 0.");
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Cannot withdraw tips from the contract.");
        totalTipsReceived = 0;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Please give a valid address.");
        require(_newOwner != msg.sender, "You cannot transfer ownership to yourself!");
        owner = _newOwner;
    } 

    function getSupportedCurencies() public view returns(string[] memory) {
        return supportedCurrencies;
    }

    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getTipsPerPerson(address _contributor) public view returns(uint256) {
        require(_contributor != address(0), "Please give a valid address.");
        return tipsPerPerson[_contributor];
    }

    function getTipsInCurrency(string memory _currencyCode) public view returns (uint256) {
        return tipsPerCurrency[_currencyCode];
    }
}
