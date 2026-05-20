// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * Plugin Contract (Logic)
 * This acts like an external "plugin"
 */
contract Plugin {

    // IMPORTANT: storage layout must match the main contract
    uint256 public number;

    function setNumber(uint256 _num) public {
        number = _num;
    }
}


/*
 * Main Contract (PluginStore)
 */
contract PluginStore {

    // SAME storage layout as Plugin
    uint256 public number;

    address public owner;

    event PluginExecuted(address plugin, uint256 newValue);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    /*
     * Execute plugin using delegatecall
     */
    function executePlugin(address _plugin, uint256 _num) public onlyOwner {

        // delegatecall executes plugin code in THIS contract's context
        (bool success, ) = _plugin.delegatecall(
            abi.encodeWithSignature("setNumber(uint256)", _num)
        );

        require(success, "Delegatecall failed");

        emit PluginExecuted(_plugin, number);
    }

    /*
     * View stored number
     */
    function getNumber() public view returns (uint256) {
        return number;
    }
}