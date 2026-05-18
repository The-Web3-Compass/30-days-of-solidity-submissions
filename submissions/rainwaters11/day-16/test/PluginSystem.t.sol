// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/PluginStore.sol";
import "../contracts/AchievementsPlugin.sol";

contract PluginSystemTest {
    PluginStore internal store;
    AchievementsPlugin internal achievements;

    address internal constant USER = address(0xBEEF);

    function setUp() public {
        store = new PluginStore();
        achievements = new AchievementsPlugin();
    }

    // ─── helpers ────────────────────────────────────────────────────────────────

    function _strEq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    // ─── tests ──────────────────────────────────────────────────────────────────

    function testRegisterPlugin() public {
        store.registerPlugin("achievements", address(achievements));
        require(store.plugins("achievements") == address(achievements), "Plugin not registered");
    }

    function testRunPluginSetsBadge() public {
        // Give the user the Web3 Pioneer badge via PluginStore.runPlugin
        store.runPlugin(
            address(achievements),
            "setBadge(address,string)",
            USER,
            "Web3 Pioneer"
        );

        // Read directly from plugin to confirm the write
        string memory badge = achievements.getBadge(USER);
        require(_strEq(badge, "Web3 Pioneer"), "Direct read: badge mismatch");
    }

    function testRunPluginViewReturnsBadge() public {
        // Write badge through PluginStore
        store.runPlugin(
            address(achievements),
            "setBadge(address,string)",
            USER,
            "Web3 Pioneer"
        );

        // Read badge back through PluginStore.runPluginView (staticcall path)
        bytes memory raw = store.runPluginView(
            address(achievements),
            "getBadge(address)",
            USER
        );

        string memory badge = abi.decode(raw, (string));
        require(_strEq(badge, "Web3 Pioneer"), "runPluginView: badge mismatch");
    }

    function testRunPluginViewByKeyReturnsBadge() public {
        store.registerPlugin("achievements", address(achievements));

        store.runPlugin(
            address(achievements),
            "setBadge(address,string)",
            USER,
            "Web3 Pioneer"
        );

        // Read via registered key
        bytes memory raw = store.runPluginViewByKey(
            "achievements",
            "getBadge(address)",
            USER
        );

        string memory badge = abi.decode(raw, (string));
        require(_strEq(badge, "Web3 Pioneer"), "runPluginViewByKey: badge mismatch");
    }

    // Bonus: runPluginViewByKey must revert when the key has never been registered.
    function testRunPluginViewByKeyRevertsForUnknownKey() public view {
        bool reverted = false;

        try store.runPluginViewByKey("nonexistent", "getBadge(address)", USER) returns (bytes memory) {
            // reaching here means the expected revert did NOT happen
        } catch {
            reverted = true;
        }

        require(reverted, "Expected PluginNotRegistered revert but call succeeded");
    }
}
