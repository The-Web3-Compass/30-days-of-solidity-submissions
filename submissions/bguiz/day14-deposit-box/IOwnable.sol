// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

/**
 * @title IOwnable
 */
interface IOwnable {
    event OwnerUpdate(address indexed prevOwner, address indexed newOwner);

    function owner() external returns(address);
    function transferOwner(address newOwner) external;
}
