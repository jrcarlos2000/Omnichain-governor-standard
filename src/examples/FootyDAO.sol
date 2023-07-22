pragma solidity ^0.8.19;

import "../core/MultichainGovernor.sol";

contract FootyDAO is MultichainGovernor {
    constructor(
        IVotes _token,
        TimelockController _timelock,
        address connectorAddress,
        address zetaTokenAddress,
        address uniswapV2Router
    )
        MultichainGovernor(
            _token,
            _timelock,
            connectorAddress,
            zetaTokenAddress,
            uniswapV2Router
        )
    {}

    function votingDelay() public pure override returns (uint256) {
        return 0;
    }

    function votingPeriod() public pure override returns (uint256) {
        return 2 days; // 1 week
    }

    function proposalThreshold() public pure override returns (uint256) {
        return 0;
    }
}
