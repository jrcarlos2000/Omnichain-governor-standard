pragma solidity ^0.8.19;

import "../core/MultichainGovernorVotes.sol";

contract FootyDAOToken is MultichainGovernorVotes {
    constructor(
        address connectorAddress,
        address zetaTokenAddress,
        address uniswapV2Router
    )
        MultichainGovernorVotes(
            "FootyDAO Token",
            "FUT",
            connectorAddress,
            zetaTokenAddress,
            uniswapV2Router
        )
    {}
}
