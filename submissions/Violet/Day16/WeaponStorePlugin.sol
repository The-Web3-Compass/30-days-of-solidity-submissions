// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract WeaponStorePlugin {
    
    // 玩家地址 => 武器名称
    mapping(address => string) public equippedWeapon;

    address public immutable storeAddress; // PluginStore合约的地址

    modifier onlyStore() {
        require(msg.sender == storeAddress, "Only callable via PluginStore");
        _;
    }

    constructor(address _storeAddress) {
        storeAddress = _storeAddress;
    }

    /**
     * @dev 为一个玩家装备一件武器 (由 PluginStore 调用)。
     * @param user 玩家地址。
     * @param weapon 武器名称。
     */
    function setWeapon(address user, string memory weapon) external onlyStore {
        equippedWeapon[user] = weapon;
    }

    /**
     * @dev 获取一个玩家当前装备的武器。
     */
    function getWeapon(address user) external view returns (string memory) {
        return equippedWeapon[user];
    }
}
