// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// BattleLogPlugin: 跟踪用户的战斗历史
// 说明：
// - 记录每次战斗的对手、结果与时间戳
// - 提供添加战斗日志、查看最新条目与按索引查询
// - 不更改已有插件的逻辑，仅新增本插件
contract BattleLogPlugin {
    struct BattleEntry {
        address opponent;
        string result; // 例如 "win", "lose", "draw" 或自定义文本
        uint256 timestamp;
    }

    // 用户 => 战斗日志列表
    mapping(address => BattleEntry[]) private logs;

    event BattleLogged(address indexed user, address indexed opponent, string result, uint256 timestamp);

    // 添加一条战斗记录
    function addBattle(address user, address opponent, string memory result) external {
        require(user != address(0) && opponent != address(0), "Invalid address");
        BattleEntry memory entry = BattleEntry({
            opponent: opponent,
            result: result,
            timestamp: block.timestamp
        });
        logs[user].push(entry);
        emit BattleLogged(user, opponent, result, block.timestamp);
    }

    // 获取最新战斗记录（返回简要描述）
    function getLatestBattleSummary(address user) external view returns (string memory) {
        BattleEntry[] storage list = logs[user];
        if (list.length == 0) {
            return "";
        }
        BattleEntry storage e = list[list.length - 1];
        // 简要字符串：opponent 地址 + 结果 + 时间戳
        // 注意：仅返回字符串摘要，详细请用索引查询
        return _concatSummary(e.opponent, e.result, e.timestamp);
    }

    // 返回战斗日志数量
    function getBattleCount(address user) external view returns (uint256) {
        return logs[user].length;
    }

    // 按索引返回完整一条记录
    function getBattleAt(address user, uint256 index) external view returns (address opponent, string memory result, uint256 timestamp) {
        require(index < logs[user].length, "Index out of bounds");
        BattleEntry storage e = logs[user][index];
        return (e.opponent, e.result, e.timestamp);
    }

    // 内部拼接简单摘要字符串
    function _concatSummary(address opponent, string memory result, uint256 ts) internal pure returns (string memory) {
        // 为简洁，直接返回 result；如需复杂拼接可在前端处理
        // 这里也可以返回固定格式 "opponent: <addr>, result: <result>, ts: <ts>"
        return result;
    }
}