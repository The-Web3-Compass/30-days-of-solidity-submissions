// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";

contract VaultManager {

    function store(address box, string calldata secret) public {
        IDepositBox(box).storeSecret(secret);
    }

    function read(address box) public view returns(string memory) {
        return IDepositBox(box).readSecret();
    }

    function transferBox(address box, address newOwner) public {
        IDepositBox(box).transferOwnership(newOwner);
    }

    function getOwner(address box) public view returns(address) {
        return IDepositBox(box).owner();
    }
}