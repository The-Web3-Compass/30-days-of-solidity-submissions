// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/MockToken.sol";
import "../src/MockV3Aggregator.sol";
import "../src/SimpleStablecoin.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        // 8-dec oracle at $2000.00
        MockV3Aggregator agg = new MockV3Aggregator(8, 2_000_00000000);

        // mint a collateral token to deployer
        MockToken collateral = new MockToken();

        // deploy stablecoin using the mock oracle
        SimpleStablecoin susd =
            new SimpleStablecoin(address(collateral), msg.sender, address(agg));

        vm.stopBroadcast();

        // optional: silence “unused” warnings via logs
        console2.log(address(agg));
        console2.log(address(collateral));
        console2.log(address(susd));
    }
}
