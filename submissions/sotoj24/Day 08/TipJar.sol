// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {

    struct TipUser {
        uint256 totalEth; // in wei
        uint256 usd;      // simulated USD value
        uint256 eur;      // simulated EUR value
    }

    mapping(address => TipUser) private userTips;

    uint256 public ethToUsdRate = 3000;
    uint256 public ethToEurRate = 2800;

    address public owner;

    constructor() {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can update rates");
        _;
    }

    function updateRates(uint256 _usdRate, uint256 _eurRate) external onlyOwner {
        ethToUsdRate = _usdRate;
        ethToEurRate = _eurRate;
    }


    function tip() external payable {
        require(msg.value > 0, "Tip amount must be greater than 0");

        TipUser storage tipper = userTips[msg.sender];
        tipper.totalEth += msg.value;
        tipper.usd += (msg.value * ethToUsdRate) / 1 ether;
        tipper.eur += (msg.value * ethToEurRate) / 1 ether;
    }


    function getMyTips() external view returns (uint256 eth, uint256 usd, uint256 eur) {
        TipUser storage tipper = userTips[msg.sender];
        return (tipper.totalEth, tipper.usd, tipper.eur);
    }


    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }


    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
