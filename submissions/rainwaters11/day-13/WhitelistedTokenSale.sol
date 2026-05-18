// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../day-12/MistyCoin.sol";

contract WhitelistedTokenSale is MistyCoin {
    uint256 public tokenPrice;
    uint256 public saleEndTime;
    address public owner;
    bool public finalized;

    mapping(address => bool) public whitelist;

    event WhitelistUpdated(address indexed account, bool isWhitelisted);
    event TokensPurchased(address indexed buyer, uint256 ethSpent, uint256 tokenAmount);
    event SaleFinalized(uint256 finalizedAt);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationSeconds
    ) MistyCoin(_initialSupply) {
        require(_tokenPrice > 0, "Token price must be > 0");

        owner = msg.sender;
        tokenPrice = _tokenPrice;
        saleEndTime = block.timestamp + _saleDurationSeconds;
        _transfer(msg.sender, address(this), totalSupply);
    }

    function setWhitelist(address _user, bool _status) external onlyOwner {
        whitelist[_user] = _status;
        emit WhitelistUpdated(_user, _status);
    }

    function buyTokens() public payable {
        require(!finalized, "Sale already finalized");
        require(block.timestamp <= saleEndTime, "Sale ended");
        require(whitelist[msg.sender], "Not whitelisted");
        require(msg.value > 0, "Send ETH to buy tokens");

        uint256 tokenAmount = (msg.value * (10 ** uint256(decimals))) / tokenPrice;

        require(tokenAmount > 0, "ETH amount too low");
        require(balanceOf[address(this)] >= tokenAmount, "Not enough sale tokens");

        _transfer(address(this), msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    receive() external payable {
        buyTokens();
    }

    function finalizeSale() external onlyOwner {
        require(!finalized, "Already finalized");
        finalized = true;
        emit SaleFinalized(block.timestamp);
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(
            finalized || block.timestamp > saleEndTime || msg.sender == owner || msg.sender == address(this),
            "Tokens are locked until sale finalization"
        );
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require(
            finalized || block.timestamp > saleEndTime || _from == owner || _from == address(this),
            "Tokens are locked until sale finalization"
        );
        return super.transferFrom(_from, _to, _value);
    }

    function withdrawETH() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "No ETH to withdraw");

        (bool sent, ) = owner.call{value: amount}("");
        require(sent, "ETH transfer failed");
    }
}