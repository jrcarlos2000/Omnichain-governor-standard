pragma solidity ^0.8.19;

import "@zetachain/protocol-contracts/contracts/evm/interfaces/ZetaInterfaces.sol";
import "@zetachain/protocol-contracts/contracts/evm/tools/ZetaInteractor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title Multichain Governor Adapter
 * @author
 * @notice Import this contract to add multichain capabilities to your governor
 */
abstract contract MultichainGovernorAdapter is ZetaInteractor, ZetaReceiver {
    event EthExchangedForZeta(uint256 amountIn, uint256 amountOut);

    error InvalidMessage();
    error NotEnoughCrossChainGas(uint256 gasSent, uint256 gasNeeded);
    error InvalidSwapAmount();
    event MultiChainCastVote(address voter, uint8 support, uint256 destChainId);

    enum ProposalState {
        Pending,
        Queued,
        Executed
    }
    mapping(uint256 => ProposalState) public proposalState;

    uint256 internal constant MAX_DEADLINE = 200;
    bytes32 internal constant CROSS_CHAIN_CAST_VOTE =
        keccak256("CROSS_CHAIN_CAST_VOTE");

    IERC20 internal immutable _zetaToken;
    uint256 internal immutable _destChainId;
    IUniswapV2Router02 internal immutable _uniswapV2Router;
    uint256 public globalGasLimit = 300000;
    uint256 public minZetaCrossChainGas = 3 * 10 ** 18;

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
    ) ZetaInteractor(connectorAddress) {
        _destChainId = destChainId;
        _zetaToken = IERC20(zetaTokenAddress);
        _uniswapV2Router = IUniswapV2Router02(uniswapV2Router);
    }

    /**
     * @param proposalId proposal id in destination chain
     * @param support 0,1,2
     */
    function castVote(
        uint256 proposalId,
        uint8 support
    ) public payable virtual {
        if (!_isValidChainId(_destChainId)) revert InvalidDestinationChainId();

        // we define a value needed for gas in ZETA
        uint256 crossChainGas = minZetaCrossChainGas; // TODO : maybe prepare oracle to pay for gas
        // user can send ether to pay for the tx fee or can send ZETA directly
        uint256 sentCrossChainGas = 0;
        if (msg.value > 0) {
            // we start by getting ZETA from gas - Uniswap V2
            sentCrossChainGas += _getZetaFromEth(msg.value);
        }
        if (sentCrossChainGas < crossChainGas) {
            // we need to get more ZETA
            _zetaToken.transferFrom(
                msg.sender,
                address(this),
                crossChainGas - sentCrossChainGas
            );
        }

        // we need to approve the connector to spend the ZETA
        _zetaToken.approve(address(connector), crossChainGas);
        bytes memory args = abi.encode(proposalId, support);
        connector.send(
            ZetaInterfaces.SendInput({
                destinationChainId: _destChainId,
                destinationAddress: interactorsByChainId[_destChainId],
                destinationGasLimit: globalGasLimit,
                message: abi.encode(CROSS_CHAIN_CAST_VOTE, msg.sender, args),
                zetaValueAndGas: crossChainGas,
                zetaParams: abi.encode("")
            })
        );
    }

    function setGlobalGasLimit(uint256 gasLimit) external virtual {
        globalGasLimit = gasLimit;
    }

    function setMinimumZetaCrossChainGas(uint256 amount) external virtual {
        minZetaCrossChainGas = amount;
    }

    function onZetaMessage(
        ZetaInterfaces.ZetaMessage calldata zetaMessage
    ) external virtual isValidMessageCall(zetaMessage) {}

    function onZetaRevert(
        ZetaInterfaces.ZetaRevert calldata zetaRevert
    ) external virtual isValidRevertCall(zetaRevert) {}

    function _getZetaFromEth(
        uint256 ethAmount
    ) internal virtual returns (uint256) {
        return _getZetaFromEthUniswapV2(ethAmount);
    }

    function _getZetaFromEthUniswapV2(
        uint256 ethAmount
    ) internal returns (uint256) {
        if (ethAmount == 0) revert InvalidSwapAmount();

        address[] memory path = new address[](2);
        path[0] = _uniswapV2Router.WETH();
        path[1] = address(_zetaToken);

        uint256[] memory amounts = _uniswapV2Router.swapExactETHForTokens{
            value: ethAmount
        }(0, path, address(this), block.timestamp + MAX_DEADLINE);

        uint256 amountOut = amounts[path.length - 1];

        emit EthExchangedForZeta(ethAmount, amountOut);

        return amountOut;
    }

    function setProposalState(
        uint256 _proposalId,
        ProposalState _state
    ) external {
        proposalState[_proposalId] = _state;
    }
}
