// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Day14 IDepositBox.sol";


abstract contract BaseDepositBox is IDepositBox {

    address private _owner;
    string private _secretMessage;
    uint256 public depositTimestamp;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    constructor(address initialOwner) {
        require(initialOwner != address(0), "Owner cannot be the zero address");
        _owner = initialOwner;
        depositTimestamp = block.timestamp;
    }

    function owner() public view virtual override returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        _owner = newOwner;
    }

    function store(string memory _secret) public virtual override onlyOwner {
        _secretMessage = _secret;
    }

    function retrieve() public view virtual override onlyOwner returns (string memory) {
        return _secretMessage;
    }
}
