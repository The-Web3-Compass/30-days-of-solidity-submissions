// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/SimpleDAO.sol";

contract DummyTarget {
    event Executed(address caller, uint256 value, uint256 when);

    function doThing(uint256 x) external payable {
        emit Executed(msg.sender, msg.value, block.timestamp);
    }
}

contract SimpleDAOTest is Test {
    SimpleDAO dao;
    DummyTarget target;

    address alice = address(0xA11CE);
    address bob   = address(0xB0B);
    address carol = address(0xC4R0L);
    address admin = address(0xDAD);

    function setUp() public {
        vm.prank(admin);
        dao = new SimpleDAO(1 hours, 2); // voting period = 1 hour, quorum = 2 votes

        // admin adds three members
        vm.prank(admin);
        dao.addMember(alice);
        vm.prank(admin);
        dao.addMember(bob);
        vm.prank(admin);
        dao.addMember(carol);

        target = new DummyTarget();
    }

    function testProposeVoteExecute() public {
        // alice proposes: call target.doThing(42) with 0 value
        vm.prank(alice);
        address;
        targets[0] = address(target);
        uint256;
        values[0] = 0;
        bytes;
        calldatas[0] = abi.encodeWithSelector(DummyTarget.doThing.selector, 42);

        vm.prank(alice);
        uint256 pid = dao.propose(targets, values, calldatas, "Call doThing(42)");

        // both alice and bob vote FOR; carol votes AGAINST
        vm.warp(block.timestamp + 10); // move time into voting window
        vm.prank(alice);
        dao.vote(pid, true);
        vm.prank(bob);
        dao.vote(pid, true);
        vm.prank(carol);
        dao.vote(pid, false);

        // advance beyond voting end
        vm.warp(block.timestamp + 1 hours + 1);

        // proposal should have passed: forVotes = 2, against = 1, quorum = 2, forVotes > againstVotes
        assertEq(dao.state(pid), "Succeeded");

        // execute
        dao.execute(pid);

        assertEq(dao.state(pid), "Executed");
    }

    function testFailDoubleVote() public {
        vm.prank(alice);
        address;
        targets[0] = address(target);
        uint256;
        values[0] = 0;
        bytes;
        calldatas[0] = abi.encodeWithSelector(DummyTarget.doThing.selector, 1);

        vm.prank(alice);
        uint256 pid = dao.propose(targets, values, calldatas, "x");

        vm.warp(block.timestamp + 10);
        vm.prank(bob);
        dao.vote(pid, true);
        vm.prank(bob);
        dao.vote(pid, true); // should revert (already voted) -> testFailDoubleVote expects revert
    }
}
