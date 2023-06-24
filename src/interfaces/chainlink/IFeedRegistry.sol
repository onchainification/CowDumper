// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFeedRegistry {
    event AccessControllerSet(address indexed accessController, address indexed sender);
    event FeedConfirmed(
        address indexed asset,
        address indexed denomination,
        address indexed latestAggregator,
        address previousAggregator,
        uint16 nextPhaseId,
        address sender
    );
    event FeedProposed(
        address indexed asset,
        address indexed denomination,
        address indexed proposedAggregator,
        address currentAggregator,
        address sender
    );
    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);

    function acceptOwnership() external;

    function confirmFeed(address base, address quote, address aggregator) external;

    function decimals(address base, address quote) external view returns (uint8);

    function description(address base, address quote) external view returns (string memory);

    function getAccessController() external view returns (address);

    function getAnswer(address base, address quote, uint256 roundId) external view returns (int256 answer);

    function getCurrentPhaseId(address base, address quote) external view returns (uint16 currentPhaseId);

    function getFeed(address base, address quote) external view returns (address aggregator);

    function getNextRoundId(address base, address quote, uint80 roundId) external view returns (uint80 nextRoundId);

    function getPhase(address base, address quote, uint16 phaseId)
        external
        view
        returns (FeedRegistryInterface.Phase memory phase);

    function getPhaseFeed(address base, address quote, uint16 phaseId) external view returns (address aggregator);

    function getPhaseRange(address base, address quote, uint16 phaseId)
        external
        view
        returns (uint80 startingRoundId, uint80 endingRoundId);

    function getPreviousRoundId(address base, address quote, uint80 roundId)
        external
        view
        returns (uint80 previousRoundId);

    function getProposedFeed(address base, address quote) external view returns (address proposedAggregator);

    function getRoundData(address base, address quote, uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function getRoundFeed(address base, address quote, uint80 roundId) external view returns (address aggregator);

    function getTimestamp(address base, address quote, uint256 roundId) external view returns (uint256 timestamp);

    function isFeedEnabled(address aggregator) external view returns (bool);

    function latestAnswer(address base, address quote) external view returns (int256 answer);

    function latestRound(address base, address quote) external view returns (uint256 roundId);

    function latestRoundData(address base, address quote)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestTimestamp(address base, address quote) external view returns (uint256 timestamp);

    function owner() external view returns (address);

    function proposeFeed(address base, address quote, address aggregator) external;

    function proposedGetRoundData(address base, address quote, uint80 roundId)
        external
        view
        returns (uint80 id, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function proposedLatestRoundData(address base, address quote)
        external
        view
        returns (uint80 id, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function setAccessController(address _accessController) external;

    function transferOwnership(address to) external;

    function typeAndVersion() external pure returns (string memory);

    function version(address base, address quote) external view returns (uint256);
}

interface FeedRegistryInterface {
    struct Phase {
        uint16 phaseId;
        uint80 startingAggregatorRoundId;
        uint80 endingAggregatorRoundId;
    }
}
