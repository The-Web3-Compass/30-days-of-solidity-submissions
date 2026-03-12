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

    function withDrawTips(uint _amount) public ownerOnly {
            if (_amount > tips) revert TipJar__NotEnoughTips();
            tips -= _amount;
            (bool success, ) = msg.sender.call{value: _amount}("");
            if (!success) revert TipJar__TransactionFailed();

            emit AmountWithdrawn(_amount);
        }

    function currencyConversionInterval(
        uint _currencycode
    ) internal returns (uint) {
        // blackbox
        return _currencycode * 10e18;
    }

    function getBalance() public view returns (uint) ownerOnly {
            return address(this).balance;
        }
}
