// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/EventEntry.sol";

contract EventEntryTest is Test {
    EventEntry public eventEntry;
    uint256 organizerKey;
    address organizer;

    function setUp() public {
        // take a deterministic private key for organizer (forge local)
        organizerKey = uint256(1); // example private key (do not use on mainnet!)
        organizer = vm.addr(organizerKey);

        vm.prank(organizer);
        eventEntry = new EventEntry("Foundry Summit", block.timestamp + 1 days, 5);
    }

    function testCheckInWorks() public {
        // Build the message hash just like contract
        bytes32 messageHash = eventEntry.getMessageHash(address(0xBEEF));
        bytes32 ethSigned = eventEntry.getEthSignedMessageHash(messageHash);

        // Sign using vm.sign (returns v,r,s)
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(organizerKey, ethSigned);

        // build signature bytes:
        bytes memory sig = abi.encodePacked(r, s, v);

        // impersonate the attendee address and call checkIn with signature.
        address attendee = address(0xBEEF);
        vm.prank(attendee);
        eventEntry.checkIn(sig);

        assertTrue(eventEntry.hasAttended(attendee));
    }

    function testRejectsInvalidSignature() public {
        // someone else signs a different address — should revert on checkIn
        bytes32 messageHash = eventEntry.getMessageHash(address(0xDEAD));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(2), messageHash); // private key 2
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.prank(address(0xBEEF));
        vm.expectRevert("Invalid signature");
        eventEntry.checkIn(sig);
    }
}
