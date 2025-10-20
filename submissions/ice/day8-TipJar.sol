// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TipJar
 * @dev 管理员设定汇率，用户可按币种投币支持，系统换算 ETH 总额。
 */
contract TipJar {
    address public admin;
    uint public supporterCount;
    uint public totalContributedInEthValue; // 用户投币折算后累计 ETH 总值（单位：wei）

    mapping(string => uint) public exchangeRates; // 1单位币种 = ? wei
    mapping(address => mapping(string => uint)) public contributions; // 每人每币种贡献
    mapping(address => bool) public hasContributed;
    string[] public supportedCurrencies;

    constructor() {
        admin = msg.sender;
    }

    /// 设置汇率，例如 setExchangeRate("USD", 1e15) 表示 1 USD = 0.001 ETH
    function setExchangeRate(string memory currency, uint rateInWei) public {
        require(msg.sender == admin, "Only admin can set rates");
        if (exchangeRates[currency] == 0) {
            supportedCurrencies.push(currency);
        }
        exchangeRates[currency] = rateInWei;
    }

    /// 查询汇率换算
    function getEthAmount(string memory currency, uint amount) public view returns (uint) {
        require(exchangeRates[currency] > 0, "Unsupported currency");
        return exchangeRates[currency] * amount;
    }

    /// 投币：msg.value 是原始 ETH 金额，系统用币种汇率换算成 ETH 值
    function contribute(string memory currency, uint currencyAmount) public payable {
        require(msg.sender != admin, "Admin cannot contribute");
        require(exchangeRates[currency] > 0, "Unsupported currency");
        require(currencyAmount > 0, "Currency amount must be > 0");

        // 计算投币金额应折算为多少 ETH（wei）
        uint expectedEth = getEthAmount(currency, currencyAmount);
        require(msg.value >= expectedEth, "Insufficient ETH for declared contribution");

        // 记录用户贡献
        contributions[msg.sender][currency] += currencyAmount;
        totalContributedInEthValue += expectedEth;

        if (!hasContributed[msg.sender]) {
            hasContributed[msg.sender] = true;
            supporterCount += 1;
        }

        // 转账给管理员
        payable(admin).transfer(msg.value);
    }

    /// 管理员查询：总收到的 ETH 折算值（不含转出影响）
    function getTotalContributedEthValue() public view returns (uint) {
        require(msg.sender == admin, "Only admin can view total");
        return totalContributedInEthValue;
    }

    /// 所有人可查人数
    function getSupporterCount() public view returns (uint) {
        return supporterCount;
    }

    /// 所有人可查支持币种
    function getSupportedCurrencies() public view returns (string[] memory) {
        return supportedCurrencies;
    }
}
