// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AutomateReady} from "./gelato/AutomateReady.sol";
import {ISafe} from "./interfaces/safe/ISafe.sol";

import {IMilkMan} from "./interfaces/milkman/IMilkMan.sol";

import {IERC20} from "./interfaces/vendored/IERC20.sol";

contract CowDungerModule is AutomateReady {
    ////////////////////////////////////////////////////////////////////////////
    // STATE VARIABLES
    ////////////////////////////////////////////////////////////////////////////

    ISafe public immutable safe;
    address[] public whitelist;

    ////////////////////////////////////////////////////////////////////////////
    // CONSTANTS
    ////////////////////////////////////////////////////////////////////////////
    address internal constant MILK_MAN = 0x11C76AD590ABDFFCD980afEC9ad951B160F02797;
    address internal constant META_PRICE_CHECKER = 0xf447Bf3CF8582E4DaB9c34C5b261A7b6AD4D6bDD;
    address internal constant SUSHI_PRICE_CHECKER = 0x5A5633909060c75e5B7cB4952eFad918c711F587;

    address internal constant USDC_MAINNET = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant WETH_GOERLI = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    uint256 internal constant MAINNET_CHAIN_ID = 1;
    uint256 internal constant GOERLI_CHAIN_ID = 5;

    ////////////////////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////////////////////

    error NotSigner(address safe, address executor);
    error ExecutionFailure(address to, bytes data, uint256 timestamp);

    ////////////////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////////////////

    event TokenWhitelisted(address token);
    event CowDungMilked(address tokenSell, uint256 soldAmount, uint256 timestamp);

    //////////////////////////////////////////////////////////////////////////
    // MODIFIERS
    //////////////////////////////////////////////////////////////////////////

    modifier isSigner(ISafe _safe) {
        address[] memory signers = _safe.getOwners();
        bool isOwner;
        for (uint256 i; i < signers.length; i++) {
            if (signers[i] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        if (!isOwner) revert NotSigner(address(_safe), msg.sender);
        _;
    }

    constructor(address _safe, address _automate, address _taskCreator) AutomateReady(_automate, _taskCreator) {
        safe = ISafe(payable(_safe));
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC
    ////////////////////////////////////////////////////////////////////////////

    receive() external payable {}

    function addTokensWhitelist(address[] calldata _tokens) external isSigner(safe) {
        for (uint256 i; i < _tokens.length; i++) {
            address token = _tokens[i];
            whitelist.push(token);
            emit TokenWhitelisted(token);
        }
    }

    function _isWhitelisted(address _token) external view returns (bool) {
        for (uint256 i; i < whitelist.length; i++) {
            if (whitelist[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function dung(uint256[] calldata _toSell) external onlyDedicatedMsgSender {
        uint256 chainId = block.chainid;
        address checker;
        // NOTE: naive check data to be zero
        bytes memory priceCheckerData;

        for (uint256 i; i < _toSell.length; i++) {
            if (_toSell[i] > 0) {
                // 1. Approve milkman
                _checkTransactionAndExecute(
                    safe, whitelist[i], abi.encodeCall(IERC20.approve, (address(MILK_MAN), _toSell[i]))
                );
                // 2. Place swap trade in milkman
                if (chainId == MAINNET_CHAIN_ID) {
                    checker = META_PRICE_CHECKER;
                } else if (chainId == GOERLI_CHAIN_ID) {
                    checker = SUSHI_PRICE_CHECKER;
                }
                _checkTransactionAndExecute(
                    safe,
                    MILK_MAN,
                    abi.encodeCall(
                        IMilkMan.requestSwapExactTokensForTokens,
                        (
                            _toSell[i],
                            whitelist[i],
                            checker == META_PRICE_CHECKER ? USDC_MAINNET : WETH_GOERLI,
                            address(safe),
                            checker,
                            priceCheckerData
                        )
                    )
                );
                emit CowDungMilked(whitelist[i], _toSell[i], block.timestamp);
            }
        }

        // Pay the Gelato automator
        (uint256 fee, address feeToken) = _getFeeDetails();
        _transfer(fee, feeToken);
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Allows executing specific calldata into an address thru a gnosis-safe, which have enable this contract as module.
    /// @param to Contract address where we will execute the calldata.
    /// @param data Calldata to be executed within the boundaries of the `allowedFunctions`.
    function _checkTransactionAndExecute(ISafe _safe, address to, bytes memory data) internal {
        if (data.length >= 4) {
            bool success = _safe.execTransactionFromModule(to, 0, data, ISafe.Operation.Call);
            if (!success) revert ExecutionFailure(to, data, block.timestamp);
        }
    }
}
