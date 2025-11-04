// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract UpgradeHub {
    address public logicContract;
    address public owner;

    // Storage variables that will persist even after logic upgrades
    mapping(address => uint256) public userPlans;
    mapping(address => uint256) public expiryDates;

    constructor(address _logicContract) {
        logicContract = _logicContract;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function upgradeTo(address _newLogic) external onlyOwner {
        logicContract = _newLogic;
    }

    fallback() external payable {
        address _impl = logicContract;
        require(_impl != address(0), "Logic contract not set");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
