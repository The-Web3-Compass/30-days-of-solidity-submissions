// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "./day14-BaseDepositBox.sol";

contract TimeLockedDepositBox is BaseDepositBox {
    uint private unlockTime;

    constructor(uint _unlockTime) {
        unlockTime = block.timestamp + _unlockTime;
    }

    modifier timeUnlocked() {
        require(block.timestamp >= unlockTime);
        _;
    }

    function getSecret()
        public
        view
        override
        onlyOwner
        timeUnlocked
        returns (string memory)
    {
        return super.getSecret();
    }

    function getBoxType()
        external
        pure
        virtual
        override
        returns (string memory)
    {
        return "Time locked deposit box";
    }

    function getUnlockTime() external view returns (uint) {
        return unlockTime;
    }

    function getRemainingUnlockTime() external view returns (uint) {
        if (block.timestamp >= unlockTime) {
            return 0;
        }
        uint remainingTime = unlockTime - block.timestamp;
        return remainingTime;
    }
}
