// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TipJar {
    event TipReceived(address indexed tipper, uint amount);
    event AmountWithdrawn(uint amount);

    error TipJar__NotEnoughTips();
    error TipJar__TransactionFailed();
    error TipJar__OwnerOnly();

    address private immutable i_owner;
    mapping(address => uint) patrons;
    uint private tips;

    modifier ownerOnly() {
        if (msg.sender != i_owner) revert TipJar__OwnerOnly();
        _;
    }

    constructor() {
        i_owner = msg.sender;
    }

    function convertCurrency(uint _currencycode) public pure returns (uint) {
        return currencyConversionInterval(_currencycode);
    }

    function tipJar() public payable {
        patrons[msg.sender] += msg.value;
        tips += msg.value;

        emit TipReceived(msg.sender, msg.value);
    }

    function withDrawTips() public payable ownerOnly {
        if(msg.value > tips) revert TipJar__NotEnoughTips();
        (bool success, ) = msg.sender.call{amount: msg.value}("");
        if (!success) revert TipJar__TransactionFailed();
        tips -= msg.value;

        emit AmountWithdrawn(msg.value);
    }

    function currencyConversionInterval(
        uint _currencycode
    ) internal returns (uint) {
        // blackbox
        return _currencycode * 10e18;
    }

    function getBalance() public pure returns (uint) ownerOnly {
        return tips;
    }
}
