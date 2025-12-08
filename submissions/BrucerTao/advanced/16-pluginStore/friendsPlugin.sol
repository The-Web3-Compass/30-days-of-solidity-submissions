// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// FriendsPlugin: 管理玩家之间的连接（好友关系）
// 说明：
// - 为简洁起见，好友关系为双向：添加或移除时同时更新双方状态
// - 提供查询是否为好友、获取好友列表等视图函数
// - 不更改已有插件的逻辑，仅新增本插件
contract FriendsPlugin {
    // 用户 => 好友地址 => 是否是好友
    mapping(address => mapping(address => bool)) public isFriend;
    // 用户 => 好友列表
    mapping(address => address[]) private friendList;

    event FriendAdded(address indexed user, address indexed friend);
    event FriendRemoved(address indexed user, address indexed friend);

    // 添加好友（双向）
    function addFriend(address user, address friend) external {
        require(user != address(0) && friend != address(0), "Invalid address");
        require(user != friend, "Cannot add self as friend");
        if (!isFriend[user][friend]) {
            isFriend[user][friend] = true;
            friendList[user].push(friend);
            emit FriendAdded(user, friend);
        }
        if (!isFriend[friend][user]) {
            isFriend[friend][user] = true;
            friendList[friend].push(user);
            emit FriendAdded(friend, user);
        }
    }

    // 移除好友（双向）
    function removeFriend(address user, address friend) external {
        require(user != address(0) && friend != address(0), "Invalid address");
        if (isFriend[user][friend]) {
            isFriend[user][friend] = false;
            _removeFromList(user, friend);
            emit FriendRemoved(user, friend);
        }
        if (isFriend[friend][user]) {
            isFriend[friend][user] = false;
            _removeFromList(friend, user);
            emit FriendRemoved(friend, user);
        }
    }

    // 查询是否为好友
    function areFriends(address a, address b) external view returns (bool) {
        return isFriend[a][b];
    }

    // 获取好友列表
    function getFriends(address user) external view returns (address[] memory) {
        return friendList[user];
    }

    // 内部：从数组移除一个地址（不保持顺序）
    function _removeFromList(address user, address friend) internal {
        address[] storage list = friendList[user];
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == friend) {
                list[i] = list[list.length - 1];
                list.pop();
                break;
            }
        }
    }
}