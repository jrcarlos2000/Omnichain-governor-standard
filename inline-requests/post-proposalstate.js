// This example shows how to calculate a continuously compounding interested rate.
// This calculation would require significant on-chain gas, but is easy for a decentralized oracle network.

// Arguments can be provided when a request is initated on-chain and used in the request source code as shown below
const ProposalId = args[0]
const ProposalStateStr = args[1]
let ProposalState = 0;
if(ProposalStateStr == "Active") {
  ProposalState = 0
}else if (ProposalStateStr == "Queued") {
  ProposalState = 1
}else if (ProposalStateStr == "Executed") {
  ProposalState = 2
}
// const ProposalId = args[0]
// const ProposalState = args[1]

const request = Functions.makeHttpRequest({
  url: `https://chainlink-func.onrender.com/api/setstate/${ProposalId}/${ProposalState}`,
  method : 'POST',
})

// Continuously-compounding interest formula: A = Pe^(rt)
const totalAmountAfterInterest = principalAmount + secondAmount;

const [response] = await Promise.all([
  request
])

// The source code MUST return a Buffer or the request will return an error message
// Use one of the following functions to convert to a Buffer representing the response bytes that are returned to the client smart contract:
// - Functions.encodeUint256
// - Functions.encodeInt256
// - Functions.encodeString
// Or return a custom Buffer for a custom byte encoding
return Functions.encodeUint256(1);
