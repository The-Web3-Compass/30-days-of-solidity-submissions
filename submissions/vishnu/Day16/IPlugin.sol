// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPlugin {
    
    function getPluginName() external pure returns (string memory);
    function getPluginVersion() external pure returns (uint256);
    function getRequiredStorageSlots() external pure returns (uint256);
    
    function initialize(address player) external;
    function isCompatible(uint256 coreVersion) external pure returns (bool);

    function execute(bytes calldata data) external returns (bytes memory);
}
