// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICowDungerModule {
    function safe() external view returns (address);

    function dung(uint256[] calldata toSell) external;

    function getWhitelist() external view returns (address[] memory);
}
