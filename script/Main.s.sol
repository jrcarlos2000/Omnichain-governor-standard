pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import "../src/examples/FootyDAOToken.sol";
import "../src/examples/FootyDAOTokenAdapter.sol";
import "../src/examples/FootyDAO.sol";
import "../src/examples/FootyDAOGovernorAdapter.sol";
import "../src/TestContract.sol";
import "../src/examples/FootyDAOFunctionsConsumer.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFunctionsBillingRegistry {
    function addConsumer(uint64 subscriptionId, address consumer) external;
}

contract ScriptPolygon is Script {
    address constant CHAINLINK_ORACLE =
        0xeA6721aC65BCeD841B8ec3fc5fEdeA6141a0aDE4;
    address constant ZETA_CHAIN_CONNECTOR =
        0x0000ecb8cdd25a18F12DAA23f6422e07fBf8B9E1;
    address constant ZETA_TOKEN = 0x0000c9eC4042283e8139c74F4c64BcD1E0b9B54f;
    address constant UNISWAPV2ROUTER =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    address constant DEPLOYED_FOOTYDAOTOKEN =
        0xD07358F3C935f63A73Ef1Ce1A9F71d09137E86FC;
    address constant DEPLOYED_FOOTYDAOTOKEN_GOERLI =
        0x8362529Df39BD4598DdDf9F7564676dAb13f43e7;

    address constant FUNCTIONS_BILLING_REGISTRY =
        0xEe9Bf52E5Ea228404bB54BCFbbDa8c21131b9039;

    uint64 subId = 1897;

    FootyDAOToken footyDaoToken;
    FootyDAO footyDao;
    TimelockController timelock;
    TestContract testContract;
    FootyDAOFunctionsConsumer footyDaoFunctionsConsumer;

    function run() public {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(pk);
        footyDaoToken = new FootyDAOToken(
            ZETA_CHAIN_CONNECTOR,
            ZETA_TOKEN,
            UNISWAPV2ROUTER
        );
        address[] memory proposers = new address[](1);
        proposers[0] = vm.addr(pk);
        address[] memory executors = new address[](1);
        executors[0] = vm.addr(pk);

        timelock = new TimelockController(0, proposers, executors, vm.addr(pk));
        footyDao = new FootyDAO(
            footyDaoToken,
            timelock,
            ZETA_CHAIN_CONNECTOR,
            ZETA_TOKEN,
            UNISWAPV2ROUTER
        );
        footyDaoFunctionsConsumer = new FootyDAOFunctionsConsumer(
            CHAINLINK_ORACLE,
            subId
        );
        IFunctionsBillingRegistry(FUNCTIONS_BILLING_REGISTRY).addConsumer(
            subId,
            address(footyDaoFunctionsConsumer)
        );

        // setup footydao
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/inline-requests/");
        path = string.concat(path, "post-proposalstate.js");
        string memory jsFile = vm.readFile(path);
        footyDaoFunctionsConsumer.setPostProposalStateSrc(jsFile);

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(footyDao));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(footyDao));

        testContract = new TestContract();
        testContract.transferOwnership(address(timelock));

        footyDaoToken.mint(vm.addr(pk), 100 ether);

        footyDaoFunctionsConsumer.transferOwnership(address(footyDao));
        footyDao.setFunctionsConsumer(address(footyDaoFunctionsConsumer));
        // ---- TEST PROPOSE ----
        address[] memory targets = new address[](1);
        targets[0] = address(testContract);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);

        calldatas[0] = abi.encodeWithSignature("setValue1(uint256)", 100);
        uint256 proposalId = footyDao.propose(
            targets,
            values,
            calldatas,
            "Test Proposal"
        );
        console.log("---------- DONE PROPOSAL ID --------");
        console.logUint(proposalId);
        // footyDaoToken = new FootyDAOToken(
        //     ZETA_CHAIN_CONNECTOR,
        //     ZETA_TOKEN,
        //     UNISWAPV2ROUTER
        // );
        // footyDaoToken.mint(vm.addr(pk), 100 ether);

        // footyDaoToken = FootyDAOToken(DEPLOYED_FOOTYDAOTOKEN);
        // footyDaoToken.setInteractorByChainId(
        //     5,
        //     abi.encode(DEPLOYED_FOOTYDAOTOKEN_GOERLI)
        // );
        // footyDaoToken.delegate(vm.addr(pk));
        vm.stopBroadcast();
    }
}

contract ScriptGoerli is Script {
    address constant ZETA_CHAIN_CONNECTOR =
        0x00005E3125aBA53C5652f9F0CE1a4Cf91D8B15eA;
    address constant ZETA_TOKEN = 0x0000c304D2934c00Db1d51995b9f6996AffD17c0;
    address constant UNISWAPV2ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address constant DEPLOYED_FOOTYDAOTOKEN =
        0x8362529Df39BD4598DdDf9F7564676dAb13f43e7;
    address constant DEPLOYED_FOOTYDAOTOKEN_MUMBAI =
        0xD07358F3C935f63A73Ef1Ce1A9F71d09137E86FC;

    FootyDAOTokenAdapter footyDaoTokenAdapter;

    function run() public {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(pk);
        // footyDaoTokenAdapter = new FootyDAOTokenAdapter(
        //     ZETA_CHAIN_CONNECTOR,
        //     ZETA_TOKEN,
        //     80001,
        //     UNISWAPV2ROUTER
        // );
        // footyDaoTokenAdapter.setInteractorByChainId(
        //     80001,
        //     abi.encode(DEPLOYED_FOOTYDAOTOKEN_MUMBAI)
        // );
        footyDaoTokenAdapter = FootyDAOTokenAdapter(DEPLOYED_FOOTYDAOTOKEN);
        IERC20(ZETA_TOKEN).approve(address(footyDaoTokenAdapter), 7 ether);
        footyDaoTokenAdapter.delegate(vm.addr(pk));
        vm.stopBroadcast();
    }
}
