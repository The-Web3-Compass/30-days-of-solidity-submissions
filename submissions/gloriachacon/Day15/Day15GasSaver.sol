// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error NotOwner();
error BadId();
error Closed();
error Voted();

contract GasSaver {
    address public immutable owner;

    struct P { bytes32 n; uint40 d; uint216 v; }
    P[] public p;
    mapping(address => uint256) public vOf;

    event Add(uint256 id, bytes32 n, uint40 d);
    event V(address a, uint256 id);

    constructor(bytes32[] memory names, uint40 dur) {
        owner = msg.sender;
        uint256 n = names.length;
        unchecked {
            for (uint256 i; i < n; ++i) {
                p.push(P(names[i], uint40(block.timestamp) + dur, 0));
                emit Add(i, names[i], uint40(block.timestamp) + dur);
            }
        }
    }

    function add(bytes32[] calldata names, uint40 dur) external {
        if (msg.sender != owner) revert NotOwner();
        uint256 s = p.length;
        uint256 n = names.length;
        unchecked {
            for (uint256 i; i < n; ++i) {
                p.push(P(names[i], uint40(block.timestamp) + dur, 0));
                emit Add(s + i, names[i], uint40(block.timestamp) + dur);
            }
        }
    }

    function vote(uint256 id) external {
        if (id >= p.length) revert BadId();
        if (vOf[msg.sender] != 0) revert Voted();
        P storage x = p[id];
        if (block.timestamp > x.d) revert Closed();
        vOf[msg.sender] = id + 1;
        unchecked { x.v += 1; }
        emit V(msg.sender, id);
    }

    function len() external view returns (uint256) { return p.length; }

    function at(uint256 id) external view returns (bytes32, uint40, uint216) {
        if (id >= p.length) revert BadId();
        P storage x = p[id];
        return (x.n, x.d, x.v);
    }

    function winner() external view returns (uint256, bytes32, uint216) {
        uint256 n = p.length;
        uint256 w;
        uint216 top;
        unchecked {
            for (uint256 i; i < n; ++i) {
                uint216 t = p[i].v;
                if (t > top) { top = t; w = i; }
            }
        }
        P storage x = p[w];
        return (w, x.n, x.v);
    }
}
