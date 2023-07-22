pragma solidity ^0.8.19;

import "../core/MultichainGovernorVotesAdapter.sol";

contract FootyDAOTokenAdapter is MultichainGovernorVotesAdapter {
    /**
     * @param connectorAddress TSS address in this chain
     * @param zetaTokenAddress ZETA address in this chain
     * @param destChainId Chain id of the core governor contract
     */
    constructor(
        address connectorAddress,
        address zetaTokenAddress,
        uint256 destChainId,
        address uniswapV2Router
    )
        MultichainGovernorVotesAdapter(
            connectorAddress,
            zetaTokenAddress,
            destChainId,
            uniswapV2Router
        )
    {}
}
