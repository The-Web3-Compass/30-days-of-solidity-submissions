// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title GasSaver
 * @dev 节省gas费的投票系统
 * Gas优化重点：
 * 1. 使用constant和immutable减少存储成本
 * 2. 优化合约大小减少部署成本
 * 3. 使用assembly优化特定操作
 */
contract GasSaver {
    // @dev 使用constant存储固定值，不占用存储槽，减少部署成本
    uint8 private constant VOTE_NONE = 0;
    uint8 private constant VOTE_SUPPORT = 1;
    uint8 private constant VOTE_AGAINST = 2;
    
    // @dev 将mapping设为private节省部署成本
    mapping(address => uint8) private _votes;
    
    // @dev 将计数器打包到一个uint256中节省存储空间和部署成本
    // @dev 前128位存储支持票数，后128位存储反对票数
    uint256 private _voteCount;
    
    // @dev owner保持immutable
    address public immutable owner;
    
    // @dev 事件定义不影响部署成本
    event Voted(address indexed voter, bool support);
    
    // @dev 使用custom error节省部署成本
    error SameVoteValue();
    
    constructor() {
        owner = msg.sender;
        // 不在构造函数中初始化其他存储变量，节省部署成本
    }
    
    /**
     * @dev 内部函数用于获取投票计数，使用assembly优化gas
     */
    function _getVoteCounts() internal view returns (uint256 supportVotes, uint256 againstVotes) {
        assembly {
            let counts := sload(_voteCount.slot)
            supportVotes := shr(128, counts)
            againstVotes := and(counts, 0xffffffffffffffffffffffffffffffff)
        }
    }
    
    /**
     * @dev 内部函数用于更新投票计数，使用assembly优化gas
     */
    function _updateVoteCounts(bool isSupport, bool isAdd) internal {
        assembly {
            let counts := sload(_voteCount.slot)
            switch and(isSupport, isAdd)
            case 1 { counts := add(counts, shl(128, 1)) }
            case 0 {
                switch isSupport
                case 1 { counts := sub(counts, shl(128, 1)) }
                default {
                    switch isAdd
                    case 1 { counts := add(counts, 1) }
                    default { counts := sub(counts, 1) }
                }
            }
            sstore(_voteCount.slot, counts)
        }
    }
    
    /**
     * @dev 优化的投票函数
     */
    function vote(bool support) external {
        uint8 newVote = support ? VOTE_SUPPORT : VOTE_AGAINST;
        uint8 oldVote = _votes[msg.sender];
        
        if(oldVote == newVote) revert SameVoteValue();
        
        _votes[msg.sender] = newVote;
        
        if(oldVote == VOTE_NONE) {
            // 首次投票
            _updateVoteCounts(support, true);
        } else {
            // 修改投票
            _updateVoteCounts(oldVote == VOTE_SUPPORT, false);
            _updateVoteCounts(support, true);
        }
        
        emit Voted(msg.sender, support);
    }
    
    /**
     * @dev 优化的查询函数
     */
    function getResults() external view returns (uint256 supportVotes, uint256 againstVotes) {
        return _getVoteCounts();
    }
    
    /**
     * @dev 优化的getter函数
     */
    function getVote(address voter) external view returns (uint8) {
        return _votes[voter];
    }
    
    /**
     * @dev 优化的检查函数
     */
    function hasVoted(address voter) external view returns (bool) {
        return _votes[voter] != VOTE_NONE;
    }
}