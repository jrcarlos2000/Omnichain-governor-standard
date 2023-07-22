pragma solidity ^0.8.19;

import "../core/MultichainGovernorFunctionsConsumer.sol";

contract FootyDAOFunctionsConsumer is MultichainGovernorFunctionsConsumer {
    constructor(
        address oracle,
        uint64 subscriptionId
    ) MultichainGovernorFunctionsConsumer(oracle, subscriptionId) {}
}
