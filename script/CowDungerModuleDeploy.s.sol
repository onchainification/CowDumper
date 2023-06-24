// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";

import {CowDungerModule} from "../src/CowDungerModule.sol";


contract CowDungerModuleDeploy is Script {
    // safe config
    address SAFE_TARGET = address(0);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    }
}