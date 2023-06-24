// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ISafe} from "../src/interfaces/safe/ISafe.sol";
import {IMilkMan} from "../src/interfaces/milkman/IMilkMan.sol";

import {IERC20} from "../src/interfaces/vendored/IERC20.sol";

contract CowDungerModule {
    ////////////////////////////////////////////////////////////////////////////
    // INMUTABLE VARIABLES
    ////////////////////////////////////////////////////////////////////////////
    ISafe public immutable safe;

    ////////////////////////////////////////////////////////////////////////////
    // CONSTANTS
    ////////////////////////////////////////////////////////////////////////////
    address internal constant MILK_MAN = 0x11C76AD590ABDFFCD980afEC9ad951B160F02797;
    address internal constant META_PRICE_CHECKER = 0xf447Bf3CF8582E4DaB9c34C5b261A7b6AD4D6bDD;
    address internal constant SUSHI_PRICE_CHECKER = 0x5A5633909060c75e5B7cB4952eFad918c711F587;

    uint256 internal constant MAINNET_CHAIN_ID = 1;
    uint256 internal constant GOERLI_CHAIN_ID = 5;

    ////////////////////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////////////////////

    error ExecutionFailure(address to, bytes data, uint256 timestamp);

    constructor(ISafe _safe) {
        safe = ISafe(_safe);
    }

    // UINT256[] TOSELL =  GOS APPROACH
    function dung(address _sellToken, address _buyToken, uint256 _amount) external {
        // 1. Approve milkman
        _checkTransactionAndExecute(
            safe, address(_sellToken), abi.encodeCall(IERC20.approve, (address(MILK_MAN), _amount))
        );

        uint256 chainId = block.chainid;
        // NOTE: naive check data to be zero
        bytes memory priceCheckerData;

        // 2. Place swap trade in milkman
        if (chainId == MAINNET_CHAIN_ID) {
            _checkTransactionAndExecute(
                safe,
                address(MILK_MAN),
                abi.encodeCall(
                    IMilkMan.requestSwapExactTokensForTokens,
                    (_amount, _sellToken, _buyToken, address(safe), META_PRICE_CHECKER, priceCheckerData)
                )
            );
        } else if (chainId == GOERLI_CHAIN_ID) {
            _checkTransactionAndExecute(
                safe,
                address(MILK_MAN),
                abi.encodeCall(
                    IMilkMan.requestSwapExactTokensForTokens,
                    (_amount, _sellToken, _buyToken, address(safe), SUSHI_PRICE_CHECKER, priceCheckerData)
                )
            );
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Allows executing specific calldata into an address thru a gnosis-safe, which have enable this contract as module.
    /// @param to Contract address where we will execute the calldata.
    /// @param data Calldata to be executed within the boundaries of the `allowedFunctions`.
    function _checkTransactionAndExecute(ISafe safe, address to, bytes memory data) internal {
        if (data.length >= 4) {
            bool success = safe.execTransactionFromModule(to, 0, data, ISafe.Operation.Call);
            if (!success) revert ExecutionFailure(to, data, block.timestamp);
        }
    }
}
