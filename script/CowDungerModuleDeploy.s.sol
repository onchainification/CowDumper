// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";

import {CowDungerModule} from "../src/CowDungerModule.sol";

contract CowDungerModuleDeploy is Script {
    // safe config
    address SAFE_TARGET = address(0);
    address GELATO_AUTOMATE_GOERLI = 0xc1C6805B857Bef1f412519C4A842522431aFed39;
    address GELATO_TASK_CREATOR_GOERLI = 0xF381dfd7a139caaB83c26140e5595C0b85DDadCd;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        address logic = address(new CowDungerModule(SAFE_TARGET,GELATO_AUTOMATE_GOERLI, GELATO_TASK_CREATOR_GOERLI));

        vm.stopBroadcast();
    }
}
