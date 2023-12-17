// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/contracts/VaultCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/LedgerCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainManagerProxy.sol";
import "evm-cross-chain/contracts/interface/ICrossChainManager.sol";
import "./BaseScript.s.sol";
import "./OperationHelper.s.sol";

contract CCManagerHelper is BaseScript, OperationHelper {
    function deployVaultManager() internal returns (address, address) {
        VaultCrossChainManagerUpgradeable vaultManager = new VaultCrossChainManagerUpgradeable();
        CrossChainManagerProxy proxy = new CrossChainManagerProxy(address(vaultManager), bytes(""));
        VaultCrossChainManagerUpgradeable(payable(proxy)).initialize();
        return (address(vaultManager), address(proxy));
    }

    function deployLedgerManager() internal returns (address, address) {
        LedgerCrossChainManagerUpgradeable vaultManager = new LedgerCrossChainManagerUpgradeable();
        CrossChainManagerProxy proxy = new CrossChainManagerProxy(address(vaultManager), bytes(""));
        LedgerCrossChainManagerUpgradeable(payable(proxy)).initialize();
        return (address(vaultManager), address(proxy));
    }

    function upgradeVaultManager(address proxy) internal returns (address) {
        VaultCrossChainManagerUpgradeable vaultManager = new VaultCrossChainManagerUpgradeable();

        VaultCrossChainManagerUpgradeable(payable(proxy)).upgradeTo(address(vaultManager));
        return address(vaultManager);
    }

    function upgradeLedgerManager(address proxy) internal returns (address) {
        LedgerCrossChainManagerUpgradeable ledgerManager = new LedgerCrossChainManagerUpgradeable();

        LedgerCrossChainManagerUpgradeable(payable(proxy)).upgradeTo(address(ledgerManager));
        return address(ledgerManager);
    }

    function setCrossChainRelay(address managerProxy, address relay) internal {
        ICrossChainManager(payable(managerProxy)).setCrossChainRelay(relay);
    }

    function setChainId(string memory network, address managerProxy) internal {
        ICrossChainManager(payable(managerProxy)).setChainId(getChainId(network));
    }

    function setVaultAddress(address vaultManagerProxy, address vaultAddress) internal {
        // debug info
        uint256 ledgerChainId = VaultCrossChainManagerUpgradeable(payable(vaultManagerProxy)).ledgerChainId();
        uint256 chainId = VaultCrossChainManagerUpgradeable(payable(vaultManagerProxy)).chainId();
        console.log("ledger Chain Id: ", ledgerChainId);
        console.log("vault Chain Id: ", chainId);
        VaultCrossChainManagerUpgradeable(payable(vaultManagerProxy)).setVault(vaultAddress);
    }

    function setLedgerAddress(address ledgerManagerProxy, address ledgerAddress) internal {
        // debug info
        uint256 chainId = LedgerCrossChainManagerUpgradeable(payable(ledgerManagerProxy)).chainId();
        console.log("chainId: ", chainId);
        LedgerCrossChainManagerUpgradeable(payable(ledgerManagerProxy)).setLedger(ledgerAddress);
    }

    function setLedgerCCManager(
        address vaultManagerProxy,
        string memory ledgerNetwork,
        address ledgerManagerProxyAddress
    ) internal {
        VaultCrossChainManagerUpgradeable(payable(vaultManagerProxy)).setLedgerCrossChainManager(
            getChainId(ledgerNetwork), ledgerManagerProxyAddress
        );
    }

    function setLedgerOperatorManager(address ledgerManagerProxy, address operator) internal {
        LedgerCrossChainManagerUpgradeable(payable(ledgerManagerProxy)).setOperatorManager(operator);
    }

    function setTokenDecimal(address ledgerManagerProxy, bytes32 tokenHash, string memory network, uint128 decimal)
        internal
    {
        LedgerCrossChainManagerUpgradeable(payable(ledgerManagerProxy)).setTokenDecimal(
            tokenHash, getChainId(network), decimal
        );
    }

    function sendTestWithdraw(address ledgerManagerProxy, string memory toNetwork) internal {
        // debug info
        address relay = address(LedgerCrossChainManagerUpgradeable(payable(ledgerManagerProxy)).crossChainRelay());
        console.log("relay address: ", relay);
        LedgerCrossChainManagerUpgradeable(payable(ledgerManagerProxy)).sendTestWithdraw(getChainId(toNetwork));
    }
}
