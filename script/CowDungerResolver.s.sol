// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

import {CowDungerResolver} from "../src/CowDungerResolver.sol";

contract CowDungerResolverDeploy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        address moduleAddress = address(new CowDungerResolver());
        console.log(moduleAddress);

        vm.stopBroadcast();
    }
}
