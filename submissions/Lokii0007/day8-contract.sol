// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract TipJar {
    address public owner;
    address[] users;
    mapping(address => bool) registeredUsers;
    mapping(address => uint256) balance;

    string[] supportedCurrencies;
    mapping(string => bool) registeredCurrencies;
    mapping(string => uint256) currencyRates;

    mapping(address => uint256) tipsPerPerson;
    mapping(string => uint256) tipsPerCountry;
    mapping(address => address[]) contributions;

    constructor() {
        owner = msg.sender;
        registeredUsers[msg.sender] = true;
        users.push(msg.sender);
    }

    modifier isRegistered() {
        require(registeredUsers[msg.sender] == true, "not registered");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier validAmount(uint _amount) {
        require(_amount > 0, "invalid amount");
        require(balance[msg.sender] >= _amount, "gareeb");
        _;
    }

    function addUser(address _newUser) public onlyOwner {
        require(_newUser != address(0), "invalid address");
        require(_newUser != msg.sender, "owner is already registered");
        require(!registeredUsers[_newUser], "already registered");

        registeredUsers[_newUser] = true;
        users.push(_newUser);
        balance[_newUser] = 0;
    }

    function addCurrency(
        string memory _currency,
        uint256 _rate
    ) public onlyOwner {
        require(!registeredCurrencies[_currency], "currency already exists");
        require(_rate > 0, "rate must be grater than 0");

        supportedCurrencies.push(_currency);
        currencyRates[_currency] = _rate;
        registeredCurrencies[_currency] = true;
    }

    function convertToEth(
        uint _amount,
        string memory _currency
    ) public view validAmount(_amount) returns (uint256) {
        require(
            registeredCurrencies[_currency],
            "this currency isnt registered"
        );

        return currencyRates[_currency] * _amount;
    }

    function donate(
        uint _amount,
        string memory _currency,
        address _receiver
    ) public isRegistered validAmount(_amount) {
        require(_receiver != address(0), "invalid address");
        require(registeredUsers[_receiver], "reciever isnt registered");
        require(
            registeredCurrencies[_currency],
            "this currency isnt registered"
        );

        uint256 convertedAmount = convertToEth(_amount, _currency);
        balance[msg.sender] -= convertedAmount;
        balance[_receiver] += convertedAmount;
        tipsPerPerson[_receiver] += convertedAmount;
        tipsPerCountry[_currency] += convertedAmount;
        contributions[_receiver].push(msg.sender);
    }

    function withdraw(uint _amount) public isRegistered validAmount(_amount) {
        balance[msg.sender] -= _amount;
    }

    function getCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }

    function getTips() public view isRegistered returns (uint256) {
        return tipsPerPerson[msg.sender];
    }

    function getContributors()
        public
        view
        isRegistered
        returns (address[] memory)
    {
        return contributions[msg.sender];
    }
}
