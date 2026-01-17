// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PluginStorage {

    struct PluginData {
        mapping(bytes32 => uint256) uintStorage;
        mapping(bytes32 => string) stringStorage;
        mapping(bytes32 => address) addressStorage;
        mapping(bytes32 => bool) boolStorage;
        mapping(bytes32 => bytes32) bytesStorage;
        mapping(bytes32 => mapping(address => uint256)) nestedUintStorage;
        mapping(bytes32 => mapping(address => bool)) nestedBoolStorage;
    }

    event StorageUpdated(address indexed plugin, bytes32 indexed key, uint256 value);
    event StorageCleared(address indexed plugin, bytes32 indexed key);

    function getStorageKey(address plugin, string memory key) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(plugin, key));
    }
    
    function setUint(PluginData storage self, address plugin, string memory key, uint256 value) internal {
        bytes32 storageKey = getStorageKey(plugin, key);
        self.uintStorage[storageKey] = value;
        emit StorageUpdated(plugin, storageKey, value);
    }
    
    function getUint(PluginData storage self, address plugin, string memory key) internal view returns (uint256) {
        bytes32 storageKey = getStorageKey(plugin, key);
        return self.uintStorage[storageKey];
    }
    
    function setString(PluginData storage self, address plugin, string memory key, string memory value) internal {
        bytes32 storageKey = getStorageKey(plugin, key);
        self.stringStorage[storageKey] = value;
    }
    
    function getString(PluginData storage self, address plugin, string memory key) internal view returns (string memory) {
        bytes32 storageKey = getStorageKey(plugin, key);
        return self.stringStorage[storageKey];
    }
    
    function setAddress(PluginData storage self, address plugin, string memory key, address value) internal {
        bytes32 storageKey = getStorageKey(plugin, key);
        self.addressStorage[storageKey] = value;
    }
    
    function getAddress(PluginData storage self, address plugin, string memory key) internal view returns (address) {
        bytes32 storageKey = getStorageKey(plugin, key);
        return self.addressStorage[storageKey];
    }
    
    function setBool(PluginData storage self, address plugin, string memory key, bool value) internal {
        bytes32 storageKey = getStorageKey(plugin, key);
        self.boolStorage[storageKey] = value;
    }
    
    function getBool(PluginData storage self, address plugin, string memory key) internal view returns (bool) {
        bytes32 storageKey = getStorageKey(plugin, key);
        return self.boolStorage[storageKey];
    }
}
