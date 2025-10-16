// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IPlugin.sol";

contract AchievementPlugin is IPlugin {
    mapping(address => uint256) public achievements;
    event AchievementUnlocked(address indexed player, string achievement);

    function execute(bytes calldata data) external override {
        (string memory achievement) = abi.decode(data, (string));
        achievements[msg.sender] += 1;
        emit AchievementUnlocked(msg.sender, achievement);
    }
}
