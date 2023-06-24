// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMilkMan {
    event SwapRequested(
        address orderContract,
        address orderCreator,
        uint256 amountIn,
        address fromToken,
        address toToken,
        address to,
        address priceChecker,
        bytes priceCheckerData
    );

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function cancelSwap(
        uint256 amountIn,
        address fromToken,
        address toToken,
        address to,
        address priceChecker,
        bytes memory priceCheckerData
    ) external;

    function initialize(address fromToken, bytes32 _swapHash) external;

    function isValidSignature(bytes32 orderDigest, bytes memory encodedOrder) external view returns (bytes4);

    function requestSwapExactTokensForTokens(
        uint256 amountIn,
        address fromToken,
        address toToken,
        address to,
        address priceChecker,
        bytes memory priceCheckerData
    ) external;

    function swapHash() external view returns (bytes32);
}
