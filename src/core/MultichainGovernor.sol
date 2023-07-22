// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/compatibility/GovernorCompatibilityBravo.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@zetachain/protocol-contracts/contracts/evm/interfaces/ZetaInterfaces.sol";
import "@zetachain/protocol-contracts/contracts/evm/tools/ZetaInteractor.sol";

interface IMultichainGovernorFunctionsConsumer {
    function postProposalState(
        uint256 proposalId,
        string memory proposalState
    ) external;
}

abstract contract MultichainGovernor is
    Governor,
    GovernorCompatibilityBravo,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl,
    ZetaInteractor,
    ZetaReceiver
{
    bytes32 internal constant CROSS_CHAIN_CAST_VOTE =
        keccak256("CROSS_CHAIN_CAST_VOTE");

    IMultichainGovernorFunctionsConsumer public functionsConsumer;

    constructor(
        IVotes _token,
        TimelockController _timelock,
        address connectorAddress,
        address zetaTokenAddress,
        address uniswapV2Router
    )
        Governor("MyGovernor")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
        GovernorTimelockControl(_timelock)
        ZetaInteractor(connectorAddress)
    {}

    function setFunctionsConsumer(
        address _functionsConsumer
    ) external onlyOwner {
        functionsConsumer = IMultichainGovernorFunctionsConsumer(
            _functionsConsumer
        );
    }

    // ---- --------- ----

    function state(
        uint256 proposalId
    )
        public
        view
        override(Governor, IGovernor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    )
        public
        override(Governor, GovernorCompatibilityBravo, IGovernor)
        returns (uint256)
    {
        uint256 proposalId = super.propose(
            targets,
            values,
            calldatas,
            description
        );
        functionsConsumer.postProposalState(proposalId, "Active");
        return proposalId;
    }

    function onZetaMessage(
        ZetaInterfaces.ZetaMessage calldata zetaMessage
    ) external override {
        (bytes32 messageType, address sender, bytes memory args) = abi.decode(
            zetaMessage.message,
            (bytes32, address, bytes)
        );
        if (messageType == CROSS_CHAIN_CAST_VOTE) {
            _onCrossChainCastVote(sender, args);
        }
    }

    function _onCrossChainCastVote(
        address account,
        bytes memory args
    ) internal {
        (uint256 proposalId, uint8 support) = abi.decode(
            args,
            (uint256, uint8)
        );
        _castVote(proposalId, account, support, "DEFAULT");
    }

    function onZetaRevert(
        ZetaInterfaces.ZetaRevert calldata zetaRevert
    ) external override isValidRevertCall(zetaRevert) {}

    function cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        public
        override(Governor, GovernorCompatibilityBravo, IGovernor)
        returns (uint256)
    {
        return super.cancel(targets, values, calldatas, descriptionHash);
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(Governor, IERC165, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
