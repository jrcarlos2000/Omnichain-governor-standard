// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/compatibility/GovernorCompatibilityBravo.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@zetachain/protocol-contracts/contracts/evm/interfaces/ZetaInterfaces.sol";
import "@zetachain/protocol-contracts/contracts/evm/tools/ZetaInteractor.sol";
import {Functions, FunctionsClient} from "../dev/functions/FunctionsClient.sol";
// import "@chainlink/contracts/src/v0.8/dev/functions/FunctionsClient.sol"; // Once published
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract MultichainGovernor is
    Governor,
    GovernorCompatibilityBravo,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl,
    ZetaInteractor,
    ZetaReceiver,
    FunctionsClient
{
    // ---- CHAINLINK ----
    using Functions for Functions.Request;

    string postProposalStateSrc;
    uint64 subscriptionId;

    bytes32 public latestRequestId;
    bytes public latestResponse;
    bytes public latestError;

    event OCRResponse(bytes32 indexed requestId, bytes result, bytes err);

    // ---- --------- ----

    constructor(
        IVotes _token,
        TimelockController _timelock,
        address connectorAddress,
        address zetaTokenAddress,
        address uniswapV2Router,
        address oracleAddress
    )
        Governor("MyGovernor")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
        GovernorTimelockControl(_timelock)
        ZetaInteractor(connectorAddress)
        FunctionsClient(oracleAddress)
    {}

    // ---- CHAINLINK ----
    function executeRequest(
        string calldata source,
        bytes calldata secrets,
        string[] calldata args,
        uint64 subscriptionId,
        uint32 gasLimit
    ) public onlyOwner returns (bytes32) {
        Functions.Request memory req;
        req.initializeRequest(
            Functions.Location.Inline,
            Functions.CodeLanguage.JavaScript,
            source
        );
        if (secrets.length > 0) {
            req.addRemoteSecrets(secrets);
        }
        if (args.length > 0) req.addArgs(args);

        bytes32 assignedReqID = sendRequest(req, subscriptionId, gasLimit);
        latestRequestId = assignedReqID;
        return assignedReqID;
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
        _postProposalState(proposalId, "EXISTING");
        return proposalId;
    }

    function setPostProposalStateSrc(string memory source) public onlyOwner {
        postProposalStateSrc = source;
    }

    function setSubscriptionId(uint64 id) public onlyOwner {
        subscriptionId = id;
    }

    function _postProposalState(
        uint256 _proposalId,
        string memory _proposalState
    ) internal returns (bytes32) {
        Functions.Request memory req;
        req.initializeRequest(
            Functions.Location.Inline,
            Functions.CodeLanguage.JavaScript,
            postProposalStateSrc
        );
        string[] memory args = new string[](2);
        args[0] = Strings.toString(_proposalId);
        args[1] = _proposalState;
        req.addArgs(args);
        bytes32 assignedReqID = sendRequest(req, subscriptionId, 300000);
        latestRequestId = assignedReqID;
        return latestRequestId;
    }

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
