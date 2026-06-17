// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TipJar {
    address public owner;

    enum Currency { USD, EUR }

    mapping(Currency => uint256) public weiPerCent;

    mapping(address => uint256) public ethContributed;

    mapping(address => uint256) public simulatedWeiContributed;

    uint256 public totalEthReceived;
    uint256 public totalSimulatedWei;

    event EtherTipped(address indexed from, uint256 amountWei, string message);
    event CurrencyTipped(address indexed from, Currency currency, uint256 amountCents, uint256 weiEquivalent, string message);
    event RateUpdated(Currency currency, uint256 weiPerCent);
    event Withdraw(address indexed to, uint256 amountWei);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 initialUsdWeiPerCent, uint256 initialEurWeiPerCent) {
        owner = msg.sender;
        weiPerCent[Currency.USD] = initialUsdWeiPerCent;
        weiPerCent[Currency.EUR] = initialEurWeiPerCent;
    }

    function tipEther(string calldata message) external payable {
        require(msg.value > 0, "Send some ETH");
        ethContributed[msg.sender] += msg.value;
        totalEthReceived += msg.value;
        emit EtherTipped(msg.sender, msg.value, message);
    }

    function tipCurrency(Currency currency, uint256 amountCents, string calldata message) external {
        require(amountCents > 0, "Amount must be > 0 cents");
        uint256 rate = weiPerCent[currency];
        require(rate > 0, "Conversion rate not set");

        uint256 weiEquivalent = amountCents * rate;

        simulatedWeiContributed[msg.sender] += weiEquivalent;
        totalSimulatedWei += weiEquivalent;

        emit CurrencyTipped(msg.sender, currency, amountCents, weiEquivalent, message);
    }

    function setRate(Currency currency, uint256 newWeiPerCent) external onlyOwner {
        require(newWeiPerCent > 0, "Rate must be > 0");
        weiPerCent[currency] = newWeiPerCent;
        emit RateUpdated(currency, newWeiPerCent);
    }

    function withdraw(address payable to, uint256 amountWei) external onlyOwner {
        require(amountWei <= address(this).balance, "Not enough balance");
        (bool ok, ) = to.call{value: amountWei}("");
        require(ok, "Transfer failed");
        emit Withdraw(to, amountWei);
    }

    function totalWeiBy(address who) external view returns (uint256) {
        return ethContributed[who] + simulatedWeiContributed[who];
    }

    function centsToWei(Currency currency, uint256 amountCents) external view returns (uint256) {
        return amountCents * weiPerCent[currency];
    }

    receive() external payable {
        ethContributed[msg.sender] += msg.value;
        totalEthReceived += msg.value;
        emit EtherTipped(msg.sender, msg.value, "");
    }
}
