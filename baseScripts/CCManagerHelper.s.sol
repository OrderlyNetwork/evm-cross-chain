// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/contracts/VaultCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/LedgerCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainManagerProxy.sol";
import "evm-cross-chain/contracts/interface/ICrossChainManager.sol";
import "./BaseScript.s.sol";
import "./OperationHelper.s.sol";

contract CCManagerHelper is BaseScript, OperationHelper {
    function deployVaultManager() internal {
        // TODO
    }

    function deployLedgerManager() internal {
        // TODO
    }

    function upgradeManager(address proxy) internal {
        // TODO
    }

    function setCrossChainRelay(address managerProxy, address relay) internal {
        // TODO
    }

    function setChainId(uint256 chainId) internal {
        // TODO
    }

    function setVaultAddress(address vaultManagerProxy, address vaultAddress) internal {
        // TODO
    }

    function setLedgerAddress(address ledgerManagerProxy, address ledgerAddress) internal {
        // TODO
    }

    function setLedgerCCManager(
        address vaultManagerProxy,
        string memory ledgerNetwork,
        address ledgerManagerProxyAddress
    ) internal {
        // TODO
    }

    function setLedgerOperatorManager(address ledgerManagerProxy, address operator) internal {
        // TODO
    }

    function setTokenDecimal(address ledgerManagerProxy, bytes32 tokenHash, uint256 tokenChainId, uint128 decimal)
        internal
    {
        // TODO
    }
}
