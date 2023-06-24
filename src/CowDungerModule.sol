// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ISafe} from "./interfaces/safe/ISafe.sol";

contract CowDungerModule {
    ////////////////////////////////////////////////////////////////////////////
    // STATE VARIABLES
    ////////////////////////////////////////////////////////////////////////////

    ISafe public immutable safe;

    address[] public restrictionList;

    bool public isWhitelist;

    ////////////////////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////////////////////

    error NotSigner(address safe, address executor);

    ////////////////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////////////////

    event RestrictionTypeChanged(bool newRestrictionType);
    event TokenRestricted(address token);

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

    constructor(ISafe _safe, bool _isWhiteList) {
        safe = ISafe(_safe);
        isWhitelist = _isWhiteList;
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC
    ////////////////////////////////////////////////////////////////////////////

    function changeRestrictionType(bool _isWhiteList) external isSigner(safe) {
        isWhitelist = _isWhiteList;
        emit RestrictionTypeChanged(_isWhiteList);
    }

    function addTokenRestrictions(address[] calldata _tokens) external isSigner(safe) {
        for (uint256 i; i < _tokens.length; i++) {
            address token = _tokens[i];
            restrictionList.push(token);
            emit TokenRestricted(token);
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL
    ////////////////////////////////////////////////////////////////////////////

    function _isRestricted(address _token) internal view returns (bool) {
        if (isWhitelist) {
            for (uint256 i; i < restrictionList.length; i++) {
                if (restrictionList[i] == _token) {
                    return true;
                }
            }
            return false;
        } else {
            for (uint256 i; i < restrictionList.length; i++) {
                if (restrictionList[i] == _token) {
                    return false;
                }
            }
            return true;
        }
    }
}