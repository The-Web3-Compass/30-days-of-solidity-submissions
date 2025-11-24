// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StableCoin.sol";

contract PegManager {
    address public owner;
    StableCoin public stableCoin;
    uint256 public ethUsdPrice;

    event EthDeposited(address indexed user, uint256 ethAmount, uint256 ldollarMinted);
    event LdollarRedeemed(address indexed user, uint256 ldollarAmount, uint256 ethReturned);
    event EthPriceUpdated(uint256 oldPrice, uint256 newPrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "PegManager: Caller is not the owner");
        _;
    }

    constructor(address _stableCoinAddress, uint256 _initialEthUsdPrice) {
        require(_stableCoinAddress != address(0), "PegManager: Invalid StableCoin address");
        require(_initialEthUsdPrice > 0, "PegManager: Initial price must be positive");

        owner = msg.sender;
        stableCoin = StableCoin(_stableCoinAddress);
        ethUsdPrice = _initialEthUsdPrice;
    }

    function updateEthPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "PegManager: Price must be positive");
        uint256 oldPrice = ethUsdPrice;
        ethUsdPrice = _newPrice;
        emit EthPriceUpdated(oldPrice, _newPrice);
    }

    function deposit() external payable {
        require(msg.value > 0, "PegManager: Deposit amount must be positive");
        require(ethUsdPrice > 0, "PegManager: ETH price not set");

        uint256 amountLdollar = (msg.value * ethUsdPrice) / 1 ether;
        require(amountLdollar > 0, "PegManager: Calculated LDOLLAR amount is zero");

        stableCoin.mint(msg.sender, amountLdollar);
        emit EthDeposited(msg.sender, msg.value, amountLdollar);
    }

    function redeem(uint256 _amountLdollar) external {
        require(_amountLdollar > 0, "PegManager: Redeem amount must be positive");
        require(ethUsdPrice > 0, "PegManager: ETH price not set");
        require(stableCoin.balanceOf(msg.sender) >= _amountLdollar, "PegManager: Insufficient LDOLLAR balance");

        uint256 amountEth = (_amountLdollar * 1 ether) / ethUsdPrice;
        require(amountEth > 0, "PegManager: Calculated ETH amount is zero");
        require(address(this).balance >= amountEth, "PegManager: Insufficient ETH reserves");

        stableCoin.burn(msg.sender, _amountLdollar);

        (bool success, ) = msg.sender.call{value: amountEth}("");
        require(success, "PegManager: ETH transfer failed");

        emit LdollarRedeemed(msg.sender, _amountLdollar, amountEth);
    }
}
