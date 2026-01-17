// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract InterestRateModel {
    uint256 public baseRatePerBlock; // 1e18 precision per-block
    uint256 public slopePerBlock;

    constructor(uint256 _baseRatePerBlock, uint256 _slopePerBlock) {
        baseRatePerBlock = _baseRatePerBlock;
        slopePerBlock = _slopePerBlock;
    }

    // cash and borrows are plain token amounts (not scaled). We return per-block rate in 1e18 fixed point.
    function getBorrowRate(uint256 cash, uint256 borrows) external view returns (uint256) {
        if (cash + borrows == 0) return baseRatePerBlock;
        // utilization = borrows / (cash + borrows) in 1e18
        uint256 util = (borrows * 1e18) / (cash + borrows);
        return baseRatePerBlock + (slopePerBlock * util) / 1e18;
    }
}
