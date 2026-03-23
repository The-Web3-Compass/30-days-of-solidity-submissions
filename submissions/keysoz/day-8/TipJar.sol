// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error TipJar__UnAuthorized(address caller);
error TipJar__UnsupportedCurrency(string currencyCode);
error TipJar__InsufficientETH(uint256 amount, uint256 price);
error TipJar__InsufficientBalance(uint256 amount, uint256 balance);
error TipJar__NotAllowedZeroAmount();
error TipJar__WithdrawalFailed();
error TipJar__AlreadyAddedCurrency(string currencyCode);
error TipJar__NonExistedCurrency(string currencyCode);

contract TipJar {
    address private s_owner;
    uint256 private ethTipsCounter;
    uint256 private totalTipsCounter;
    address[] private contributors;
    string[] private supportedCurrencies;

    mapping(address => uint256) private tippingContributor;
    mapping(string => uint256) private codeToPrice;
    mapping(string => bool) private currencyExisted;
    mapping(string => uint256) private currencyCounter;
    mapping(address => bool) private isContributor;

    event TipReceived(address sender, uint256 amount, string currencyCode);
    event NewCurrencyAdded(string currencyCode, uint256 currencyPrice);
    event Withdrawal(address owner, uint256 amount);
    event OwnershipTransferred(address oldOwner, address newOwner);

    constructor() {
        s_owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != s_owner) revert TipJar__UnAuthorized(msg.sender);
        _;
    }

    modifier checkCurrency(string memory currencyCode) {
        if (currencyExisted[currencyCode]) revert TipJar__AlreadyAddedCurrency(currencyCode);
        _;
    }

    modifier checkZeroAmount(uint256 amount) {
        if (amount == 0) revert TipJar__NotAllowedZeroAmount();
        _;
    }

    modifier checkValidCurrencyCode(string memory currencyCode) {
        if (!currencyExisted[currencyCode]) revert TipJar__NonExistedCurrency(currencyCode);
        _;
    }

    function withdrawTips(uint256 amount) external onlyOwner checkZeroAmount(amount) {
        uint256 totalBalance = address(this).balance;
        if (amount > totalBalance) revert TipJar__InsufficientBalance(amount, totalBalance);
        emit Withdrawal(s_owner, amount);
        (bool success,) = payable(s_owner).call{value: amount}("");
        if (!success) revert TipJar__WithdrawalFailed();
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Non valid address");
        address oldOwner = s_owner;
        s_owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function addCurrency(string calldata currencyCode, uint256 currencyPrice)
        external
        onlyOwner
        checkCurrency(currencyCode)
        checkZeroAmount(currencyPrice)
    {
        currencyExisted[currencyCode] = true;
        codeToPrice[currencyCode] = currencyPrice;
        supportedCurrencies.push(currencyCode);
        emit NewCurrencyAdded(currencyCode, currencyPrice);
    }

    function sendTipInEth() external payable checkZeroAmount(msg.value) {
        address sender = msg.sender;
        uint256 amount = msg.value;
        if (!isContributor[sender]) {
            contributors.push(sender);
            isContributor[sender] = true;
        }
        ethTipsCounter++;
        totalTipsCounter++;
        tippingContributor[sender] += amount;
        emit TipReceived(sender, amount, "ETH");
    }

    function sendTipInCurrency(uint256 amount, string calldata currencyCode)
        external
        payable
        checkZeroAmount(amount)
        checkValidCurrencyCode(currencyCode)
    {
        address sender = msg.sender;
        uint256 amountInEth = convertToEth(amount, currencyCode);
        if (msg.value != amountInEth) revert TipJar__InsufficientETH(msg.value, amountInEth);
        if (!isContributor[sender]) {
            contributors.push(sender);
            isContributor[sender] = true;
        }
        tippingContributor[sender] += amountInEth;
        currencyCounter[currencyCode] += 1;
        totalTipsCounter++;
        emit TipReceived(sender, amount, currencyCode);
    }

    function convertToEth(uint256 amount, string memory currencyCode) public view returns (uint256) {
        uint256 price = codeToPrice[currencyCode];
        uint256 convertedValue = (amount * 1e18) / price;
        return convertedValue;
    }

    function getOwner() external view returns (address) {
        return s_owner;
    }

    function getTotalBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getSupportedCurrencies() external view returns (string[] memory) {
        return supportedCurrencies;
    }

    function getEthTotalTips() external view returns (uint256) {
        return ethTotalTips;
    }

    function getContributorsList() external view returns (address[] memory) {
        return contributors;
    }

    function getContributorAmount(address contributor) external view returns (uint256) {
        return (tippingContributor[contributor]);
    }

    function getCurrencyTotalTips(string memory currencyCode) external view returns (uint256) {
        return currencyCounter[currencyCode];
    }
}
