// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Functions, FunctionsClient} from "../dev/functions/FunctionsClient.sol";
// import "@chainlink/contracts/src/v0.8/dev/functions/FunctionsClient.sol"; // Once published
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract MultichainGovernorFunctionsConsumer is
    FunctionsClient,
    Ownable
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
        address oracleAddress,
        uint64 _subscriptionId
    ) FunctionsClient(oracleAddress) {
        subscriptionId = _subscriptionId;
    }

    function setPostProposalStateSrc(string memory source) public onlyOwner {
        postProposalStateSrc = source;
    }

    function postProposalState(
        uint256 _proposalId,
        string memory _proposalState
    ) external onlyOwner returns (bytes32) {
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

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        latestResponse = response;
        latestError = err;
        emit OCRResponse(requestId, response, err);
    }
}
