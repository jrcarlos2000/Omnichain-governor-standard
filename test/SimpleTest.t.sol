pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/examples/FootyDAOToken.sol";

interface Connector {
    function onReceive(
        bytes calldata,
        uint256,
        address,
        uint256,
        bytes calldata,
        bytes32
    ) external;

    function tssAddress() external view returns (address);
}

contract SimpleTest is Test {
    FootyDAOToken token;
    bytes32 internal constant CROSS_CHAIN_DELEGATE_VOTE =
        keccak256("CROSS_CHAIN_DELEGATE_VOTE");
    address connector = vm.addr(0xDA1);
    address zetaToken = vm.addr(0xDA2);
    address uniswapv2 = vm.addr(0xDA3);

    address addressInGoerli = vm.addr(0xDA4);

    address account1 = vm.addr(vm.envUint("DEPLOYER_PRIVATE_KEY"));

    function setUp() public {
        token = new FootyDAOToken(connector, zetaToken, uniswapv2);
        token.mint(account1, 100 ether);
        token.setInteractorByChainId(5, abi.encode(addressInGoerli));
    }

    function testrun() public {
        vm.prank(account1);
        token.delegate(account1);
    }

    function testOnReceive() public {
        ZetaInterfaces.ZetaMessage memory zetaMessage = ZetaInterfaces
            .ZetaMessage(
                abi.encode(addressInGoerli),
                5,
                address(token),
                5 ether,
                abi.encode(
                    CROSS_CHAIN_DELEGATE_VOTE,
                    account1,
                    abi.encode(account1)
                )
            );
        vm.prank(connector);
        token.onZetaMessage(zetaMessage);
        console.logBytes(zetaMessage.message);
        // token.delegate(account1);
        vm.roll(block.timestamp + 2);
        vm.warp(block.timestamp + 10000);

        require(token.getPastVotes(account1, block.number - 1) == 100 ether);
    }

    // function testWithFork() public {
    //     uint256 polygonfork = vm.createFork(vm.envString("MUMBAI_RPC"));
    //     token = FootyDAOToken(0xC01011C96781eEFBBb169b7F70e06AF29c950F7e);
    //     vm.selectFork(polygonfork);
    //     vm.roll(38196092);
    //     console.log("print interactor");
    //     console.logBytes(token.interactorsByChainId(5));
    //     // ZetaInterfaces.ZetaMessage memory zetaMessage = ZetaInterfaces
    //     //     .ZetaMessage(
    //     //         token.interactorsByChainId(5),
    //     //         5,
    //     //         address(0x0000c9eC4042283e8139c74F4c64BcD1E0b9B54f),
    //     //         5 ether,
    //     //         abi.encode(
    //     //             CROSS_CHAIN_DELEGATE_VOTE,
    //     //             account1,
    //     //             abi.encode(account1)
    //     //         )
    //     //     );
    //     Connector connectorPolygon = Connector(
    //         0x0000ecb8cdd25a18F12DAA23f6422e07fBf8B9E1
    //     );
    //     console.logAddress(connectorPolygon.tssAddress());
    //     bytes memory interactor = token.interactorsByChainId(5);
    //     vm.prank(connectorPolygon.tssAddress());
    //     console.logString("MESSAGE --------------");
    //     console.logBytes(
    //         abi.encode(
    //             CROSS_CHAIN_DELEGATE_VOTE,
    //             account1,
    //             abi.encode(account1)
    //         )
    //     );
    //     // connectorPolygon.onReceive(
    //     //     interactor,
    //     //     5,
    //     //     0x23AaAC5e7BcA6fbde9Cf92f5d92e7F6218477003,
    //     //     999928498240627150,
    //     //     abi.encode(
    //     //         CROSS_CHAIN_DELEGATE_VOTE,
    //     //         account1,
    //     //         abi.encode(account1)
    //     //     ),
    //     //     0xd88199fd6b32d48c81b0d71ecdd8d62b16a4cbf21f63a8a9ad603f62fe44aa52
    //     // );

    //     // bytes memory myBytes = abi.encode(
    //     //     interactor,
    //     //     uint256(5),
    //     //     0x23AaAC5e7BcA6fbde9Cf92f5d92e7F6218477003,
    //     //     uint256(999928498240627150),
    //     //     abi.encode(
    //     //         CROSS_CHAIN_DELEGATE_VOTE,
    //     //         account1,
    //     //         abi.encode(account1)
    //     //     ),
    //     //     bytes32(
    //     //         0x14fb5a84a8cbdf0f2e7611dfa407c27081acc8d9b6cba0dc0478503c4fa47669
    //     //     )
    //     // );

    //     bytes4 selector = 0x29dd214d;
    //     bytes32 input1 = 0x00000000000000000000000000000000000000000000000000000000000000c0;
    //     bytes32 input2 = 0x0000000000000000000000000000000000000000000000000000000000000005;
    //     bytes32 input3 = 0x000000000000000000000000c01011c96781eefbbb169b7f70e06af29c950f7e;
    //     bytes32 input4 = 0x0000000000000000000000000000000000000000000000000de075ab51133a4c;
    //     bytes32 input5 = 0x0000000000000000000000000000000000000000000000000000000000000100;
    //     bytes32 input6 = 0xf7b8740b87e346e2930cbcb5acf66e35d299e410d60c7ca66b2deaec3fa19667;
    //     bytes32 input7 = 0x0000000000000000000000000000000000000000000000000000000000000014;
    //     bytes32 input8 = 0x0da0063089979e3776842d8bc782d2c7bf05b4c0000000000000000000000000;
    //     bytes32 input9 = 0x00000000000000000000000000000000000000000000000000000000000000a0;
    //     bytes32 input10 = 0xcb30b7a91bfafdecc5aabe95f3f005b0c706843fcfa340dcecee64fb1056bf54;
    //     bytes32 input11 = 0x000000000000000000000000de3089d40f3491de794fbb1eca109fac36f889d0;
    //     bytes32 input12 = 0x0000000000000000000000000000000000000000000000000000000000000060;
    //     bytes32 input13 = 0x0000000000000000000000000000000000000000000000000000000000000020;
    //     bytes32 input14 = 0x000000000000000000000000de3089d40f3491de794fbb1eca109fac36f889d0;

    //     bytes memory call = abi.encodePacked(
    //         selector,
    //         input1,
    //         input2,
    //         input3,
    //         input4,
    //         input5,
    //         input6,
    //         input7,
    //         input8,
    //         input9,
    //         input10,
    //         input11,
    //         input12,
    //         input13,
    //         input14
    //     );

    //     // console.logString("Other bytes");

    //     // address interactorDecoded = abi.decode(interactor, (address));
    //     // bytes memory zetaBytes = abi.encode(
    //     //     interactorDecoded,
    //     //     5,
    //     //     0x23AaAC5e7BcA6fbde9Cf92f5d92e7F6218477003,
    //     //     999928498240627150,
    //     //     abi.encode(
    //     //         CROSS_CHAIN_DELEGATE_VOTE,
    //     //         account1,
    //     //         abi.encode(account1)
    //     //     ),
    //     //     0x14fb5a84a8cbdf0f2e7611dfa407c27081acc8d9b6cba0dc0478503c4fa47669
    //     // );

    //     // console.logBytes(zetaBytes);

    //     (bool success, ) = payable(address(connectorPolygon)).call{value: 0}(
    //         call
    //     );
    //     require(success);
    //     vm.roll(38196092 + 3);
    //     vm.warp(block.timestamp + 10000);
    //     require(token.balanceOf(account1) == 100 ether);
    //     require(token.getPastVotes(account1, 38196092 + 1) == 100 ether);
    // }
}
