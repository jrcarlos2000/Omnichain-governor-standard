// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@zetachain/protocol-contracts/contracts/evm/interfaces/ZetaInterfaces.sol";
import "@zetachain/protocol-contracts/contracts/evm/tools/ZetaInteractor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

abstract contract MultichainGovernorVotes is
    ERC20,
    ERC20Permit,
    ERC20Votes,
    ZetaInteractor,
    ZetaReceiver
{
    bytes32 internal constant CROSS_CHAIN_DELEGATE_VOTE =
        keccak256("CROSS_CHAIN_DELEGATE_VOTE");

    constructor(
        string memory _name,
        string memory _symbol,
        address connectorAddress,
        address zetaTokenAddress,
        address uniswapV2Router
    )
        ERC20(_name, _symbol)
        ERC20Permit(_name)
        ZetaInteractor(connectorAddress)
    {}

    function onZetaMessage(
        ZetaInterfaces.ZetaMessage calldata zetaMessage
    ) external override isValidMessageCall(zetaMessage) {
        (bytes32 messageType, address sender, bytes memory args) = abi.decode(
            zetaMessage.message,
            (bytes32, address, bytes)
        );
        if (messageType == CROSS_CHAIN_DELEGATE_VOTE) {
            _onCrossChainDelegateVote(sender, args);
        }
    }

    function onZetaRevert(
        ZetaInterfaces.ZetaRevert calldata zetaRevert
    ) external override isValidRevertCall(zetaRevert) {}

    function _onCrossChainDelegateVote(
        address sender,
        bytes memory args
    ) internal virtual {
        address delegatee = abi.decode(args, (address));
        _delegate(sender, delegatee);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    /**
     * @dev dummy mint to get tokens for test
     */
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function clock() public view override returns (uint48) {
        return SafeCast.toUint48(block.timestamp);
    }
}
