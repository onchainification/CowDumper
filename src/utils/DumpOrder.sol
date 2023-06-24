// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ICoWSwapSettlement} from "../../src/interfaces/cowswap/ICoWSwapSettlement.sol";
import {GPv2Order} from "../../src/interfaces/vendored/GPv2Order.sol";
import {EIP1271Verifier, GPv2EIP1271} from "../../src/interfaces/vendored/GPv2EIP1271.sol";
import {ICoWSwapOnchainOrders} from "../../src/interfaces/cowswap/ICoWSwapOnchainOrders.sol";

import {IAggregatorV3} from "../../src/interfaces/chainlink/IAggregatorV3.sol";
import {IFeedRegistry} from "../../src/interfaces/chainlink/IFeedRegistry.sol";

import {IERC20} from "../../src/interfaces/vendored/IERC20.sol";

contract DumpOrder is GPv2EIP1271 {
    struct OrderHashValidity {
        bool isValid;
        uint256 deadline;
    }

    // storage
    address public immutable recipient;
    bytes32 public immutable domainSeparator;
    mapping(bytes32 => bool) public orderHashes;

    // misc.
    uint256 internal constant DEFAULT_DEADLINE = 1 hours;
    uint256 internal constant MAX_BPS = 10_000;
    address internal constant USD_QUOTE = 0x0000000000000000000000000000000000000348;

    // cowswap
    ICoWSwapSettlement internal constant COW_SETTLEMENT = ICoWSwapSettlement(0x9008D19f58AAbD9eD0D60971565AA8510560ab41);
    address internal COW_VAULT = 0xC92E8bdf79f0507f65a392b0ab4667716BFE0110;
    bytes32 internal constant APP_DATA = keccak256("tokens dumperony");

    // chainlink
    IFeedRegistry internal constant CL_FEED_REGISTRY = IFeedRegistry(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf);

    // errors
    error ZERO_ADDRESS();
    error MIN_AMOUNT_ZERO();
    error NOT_ALLOW_ZERO_SELL();
    error INVALID_HASH_ORDER(bytes32 hash);
    error ORDER_EXPIRED(uint256 timestamp, uint256 deadline);

    constructor(address _orderRecipient) {
        if (_orderRecipient == address(0)) revert ZERO_ADDRESS();
        recipient = _orderRecipient;
        domainSeparator = COW_SETTLEMENT.domainSeparator();
    }

    function isValidSignature(bytes32 hash, bytes calldata) external view returns (bytes4 magicValue) {
        OrderHashValidity memory orderHash = orderHashes[hash];
        if (!orderHash.isValid) revert INVALID_HASH_ORDER(hash);
        if (block.timestamp > orderHash.deadline) revert ORDER_EXPIRED(block.timestamp, orderHash.deadline);
        magicValue = GPv2EIP1271.MAGICVALUE;
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL METHODS
    ////////////////////////////////////////////////////////////////////////////

    /// @param _sellToken Address of the token to be sold
    /// @param _buyToken Target token to buy
    /// @param _amount Amount of the sold token
    function _dumpOrder(address _sellToken, address _buyToken, uint256 _amount)
        internal
        returns (bytes32 memory orderId_)
    {
        if (_amount == 0) revert NOT_ALLOW_ZERO_SELL();

        // 1. Approve token x in vault
        IERC20(_sellToken).approve(COW_VAULT, _amount);

        uint256 minBuyAmount = _buyAmoutCalc(_sellToken, _buyToken, _amount);

        if (minBuyAmount == 0) revert MIN_AMOUNT_ZERO();

        // 2. Order creation details
        GPv2Order.Data memory orderDetails = GPv2Order.Data({
            sellToken: IERC20(_sellToken),
            buyToken: IERC20(_buyToken),
            receiver: recipient,
            sellAmount: _amount,
            buyAmount: _buyAmoutCalc(_sellToken, _buyToken, _amount),
            validTo: block.timestamp + DEFAULT_DEADLINE,
            appData: APP_DATA,
            feeAmount: _maxFeeAmount(_amount),
            kind: GPv2Order.KIND_SELL,
            partiallyFillable: false,
            sellTokenBalance: GPv2Order.BALANCE_ERC20,
            buyTokenBalance: GPv2Order.BALANCE_ERC20
        });

        bytes32 orderHash = orderDetails.hash(domainSeparator);
        // NOTE: use for validating the signature
        orderHashes[orderHash] = OrderHashValidity({isValid: true, deadline: block.timestamp + DEFAULT_DEADLINE});

        // 3. Order sign via 1271
        ICoWSwapOnchainOrders.OnchainSignature memory signature = ICoWSwapOnchainOrders.OnchainSignature({
            scheme: ICoWSwapOnchainOrders.OnchainSigningScheme.Eip1271,
            data: abi.encodePacked(address(this))
        });

        emit OrderPlacement(address(this), orderDetails, signature, data);
    }

    function _maxFeeAmount(uint256 _amount) internal returns (uint256) {
        // NOTE: naive calc approach, default to 10%
        return (_amount * 1_000) / MAX_BPS;
    }

    function _buyAmoutCalc(address _sellToken, address _buyToken, uint256 _amount) internal returns (uint256) {
        // 1. Check for oracle price existance in CL feed registry
        try CL_FEED_REGISTRY.getFeed(_sellToken, USD_QUOTE) returns (address oracleAddress) {
            IAggregatorV3 oracle = IAggregatorV3(oracleAddress);
            // 2. Query price _sellToken/_buyToken
            uint256 price = oracle.latestRoundData();

            // 3. Multiply by the amt
            uint256 buyTokenAmount = (_amount * price) / (10 ** oracle.decimals());

            // 4. Add slipp. factor
            return (buyTokenAmount * 9_500) / MAX_BPS;
        } catch {}
    }
}
