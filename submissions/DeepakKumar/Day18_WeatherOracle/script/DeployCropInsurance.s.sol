// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/CropInsurance.sol";

contract DeployCropInsurance is Script {
    function run() external {
        uint256 key = vm.envUint("PRIVATE_KEY");
        address consumer = vm.envAddress("CONSUMER_ADDRESS");

        vm.startBroadcast(key);
        CropInsurance insurance = new CropInsurance(consumer);
        console.log("CropInsurance deployed at:", address(insurance));
        vm.stopBroadcast();
    }
}
