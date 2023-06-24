// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AutomateReady} from "./gelato/AutomateReady.sol";
import {ISafe} from "./interfaces/safe/ISafe.sol";

contract CowDungerModule is AutomateReady {
    ////////////////////////////////////////////////////////////////////////////
    // STATE VARIABLES
    ////////////////////////////////////////////////////////////////////////////

    ISafe public immutable safe;
    address[] public whitelist;

    ////////////////////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////////////////////

    error NotSigner(address safe, address executor);

    ////////////////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////////////////

    event TokenWhitelisted(address token);

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

    constructor(
        ISafe _safe,
        address _automate,
        address _taskCreator
    ) AutomateReady(_automate, _taskCreator) {
        safe = ISafe(_safe);
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC
    ////////////////////////////////////////////////////////////////////////////

    receive() external payable {}

    function addTokensWhitelist(
        address[] calldata _tokens
    ) external isSigner(safe) {
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

    function dung(uint256[] calldata toSell) external onlyDedicatedMsgSender {
        for (uint256 i; i < toSell.length; i++) {
            // TODO: milkman.swap(this.whitelist[i], toSell[i], this.safe)
            // TODO: emit CowDungMilked event
        }

        // Pay the Gelato automator
        (uint256 fee, address feeToken) = _getFeeDetails();
        _transfer(fee, feeToken);
    }
}
