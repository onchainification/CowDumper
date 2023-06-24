// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ISafe} from "./safe/ISafe.sol";

interface ICowDungerModule {
    function safe() external view returns (ISafe);

    function dung(uint256[] calldata toSell) external;

    function whitelistLength() external view returns (uint256);

    function whitelist(uint256 index) external view returns (address);
}
