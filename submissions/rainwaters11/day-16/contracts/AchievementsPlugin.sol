// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AchievementsPlugin {
    mapping(address => string) private userBadge;

    event BadgeSet(address indexed user, string badge);

    function setBadge(address user, string calldata badge) external {
        require(msg.sender == user, "Only user can set own badge");
        userBadge[user] = badge;
        emit BadgeSet(user, badge);
    }

    function getBadge(address user) external view returns (string memory) {
        return userBadge[user];
    }
}
