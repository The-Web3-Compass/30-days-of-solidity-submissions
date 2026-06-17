// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/StableUSD.sol";
import "../src/OracleManager.sol";
import "../src/CollateralPool.sol";
import "../src/MockOracle.sol";
import "../src/Treasury.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        StableUSD s = new StableUSD();
        OracleManager om = new OracleManager();
        CollateralPool pool = new CollateralPool(address(s), address(om));
        Treasury t = new Treasury(address(s));
        // example usage: deploy mock oracle for a token later in tests or manual actions

        vm.stopBroadcast();
    }
}