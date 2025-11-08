// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GovernanceToken {
    string public constant name = "Governance Token";
    string public constant symbol = "GOV";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => address) public delegates;
    struct Checkpoint {
        uint256 fromBlock;
        uint256 votes;
    }
    
    mapping(address => Checkpoint[]) public checkpoints;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event DelegateChanged(
        address indexed delegator, 
        address indexed fromDelegate, 
        address indexed toDelegate
    );
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );
    
    constructor(uint256 initialSupply) {
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }
    

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        emit Transfer(msg.sender, to, amount);

        _moveDelegates(delegates[msg.sender], delegates[to], amount);
        
        return true;
    }

    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    function getVotes(address account) external view returns (uint256) {
        uint256 length = checkpoints[account].length;
        return length > 0 ? checkpoints[account][length - 1].votes : 0;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = balanceOf[delegator];
        
        delegates[delegator] = delegatee;
        emit DelegateChanged(delegator, currentDelegate, delegatee);
        
        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }
    
    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = checkpoints[srcRep].length;
                uint256 srcRepOld = srcRepNum > 0 
                    ? checkpoints[srcRep][srcRepNum - 1].votes 
                    : 0;
                uint256 srcRepNew = srcRepOld - amount;
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }
            
            if (dstRep != address(0)) {
                uint256 dstRepNum = checkpoints[dstRep].length;
                uint256 dstRepOld = dstRepNum > 0 
                    ? checkpoints[dstRep][dstRepNum - 1].votes 
                    : 0;
                uint256 dstRepNew = dstRepOld + amount;
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }
    
    function _writeCheckpoint(
        address delegatee,
        uint256 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == block.number) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee].push(Checkpoint(block.number, newVotes));
        }
        
        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
}
