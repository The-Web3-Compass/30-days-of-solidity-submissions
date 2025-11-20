// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AutomatedMarketMaker.sol";

contract DeployAMM is Script {
    function run() external returns (AutomatedMarketMaker amm) {
        address tokenA = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
        address tokenB = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;

        vm.startBroadcast();

        amm = new AutomatedMarketMaker(
            tokenA,
            tokenB,
            "LP Token",
            "LPT"
        );

        vm.stopBroadcast();
    }
}
