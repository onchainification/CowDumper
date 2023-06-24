// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "./interfaces/oz/IERC20.sol";
import {ICowDungerModule} from "./interfaces/ICowDungerModule.sol";
import {ISafe} from "./interfaces/safe/ISafe.sol";

/// @title CowDungerResolver
/// @author gosuto.eth
/// @notice A Gelato resolver which signals if there are any whitelisted tokens
/// to sell in the CowDungerModule's multisig
/// @dev https://docs.gelato.network/developer-services/automate/guides/custom-logic-triggers/smart-contract-resolvers
contract CowDungerResolver {
    function checker(address cowDungerModule) external view returns (bool canExec, bytes memory execPayload) {
        ISafe safe = ICowDungerModule(cowDungerModule).safe();
        address[] memory whitelist = ICowDungerModule(cowDungerModule).whitelist();
        uint256[] memory toSell = new uint256[](whitelist.length);
        for (uint256 idx = 0; idx < whitelist.length; idx++) {
            uint256 balance = IERC20(whitelist[idx]).balanceOf(address(safe));
            if (balance > 0) {
                toSell[idx] = balance;
                canExec = true;
            }
        }
        if (canExec) {
            execPayload = abi.encodeCall(ICowDungerModule.dung, toSell);
        }
    }
}
