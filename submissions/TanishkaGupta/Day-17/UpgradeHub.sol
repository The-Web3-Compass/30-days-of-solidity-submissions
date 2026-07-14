// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * Logic Contract V1
 * Contains actual functionality
 */
contract LogicV1 {

    // MUST match storage layout of proxy
    uint256 public value;

    function setValue(uint256 _value) public {
        value = _value;
    }
}


/*
 * Proxy Contract (UpgradeHub)
 */
contract UpgradeHub {

    // SAME storage layout as Logic contract
    uint256 public value;

    address public implementation;
    address public owner;

    event Upgraded(address newImplementation);

    constructor(address _impl) {
        implementation = _impl;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    /*
     * Upgrade logic contract
     */
    function upgrade(address _newImplementation) public onlyOwner {
        implementation = _newImplementation;
        emit Upgraded(_newImplementation);
    }

    /*
     * Delegate calls to implementation
     */
    fallback() external payable {

        address impl = implementation;

        require(impl != address(0), "No implementation");

        assembly {
            // copy msg.data
            calldatacopy(0, 0, calldatasize())

            // delegatecall to implementation
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            // copy returned data
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}