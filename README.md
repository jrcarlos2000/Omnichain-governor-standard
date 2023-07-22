### Modify the following files after `forge build`
 - lib/protocol-contracts/contracts/evm/interfaces/ZetaInteractorErrors.sol
 - lib/protocol-contracts/contracts/evm/interfaces/ZetaInterfaces.sol
 - lib/protocol-contracts/contracts/evm/tools/ZetaInteractor.sol


## **DeployScripts**
```bash
// polygonMumbai
forge script script/Main.s.sol:ScriptPolygon --rpc-url polygonMumbai --etherscan-api-key NDZZQB529Q8HQAUXZEARWCHGZBRGDMSEYC --verifier-url https://api-testnet.polygonscan.com/api --broadcast --verify --legacy
```

```bash
// bscTesnet 
forge script script/Main.s.sol:ScriptBscTestnet --rpc-url bscTestnet --etherscan-api-key IG2WK5KH5CFH1DRYU42MXHHCCCJDWX65RD --verifier-url https://api-testnet.bscscan.com/api --broadcast --verify --legacy
```

```bash
// goerli
forge script script/Simple.s.sol:ScriptGoerli --rpc-url goerli --etherscan-api-key Y6H9S7521BGREFMGSETVA72F1HT74FE3M5 --verifier-url https://api-goerli.etherscan.io/api --broadcast --verify --legacy
```
