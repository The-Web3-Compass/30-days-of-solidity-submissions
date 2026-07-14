// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./vaultMaster.sol";
contract AccessControl is vaultMaster {
    mapping(address => bool) public admins;
    mapping(address => bool) public otherAdmins;
    event newAdmins(address indexed newAdmin);

    function givePermission(address _newAdmin) public onlyOwner {
        require(_newAdmin != address(0), "no address found");
        admins[_newAdmin] = true;

        emit newAdmins(_newAdmin);
    }
}
