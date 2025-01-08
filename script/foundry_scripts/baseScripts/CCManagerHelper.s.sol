// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/contracts/VaultCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/LedgerCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/OrderlyProxy.sol";
import "evm-cross-chain/contracts/interface/ICrossChainManager.sol";
import "./BaseScript.s.sol";
import "./OperationHelper.s.sol";

contract CCManagerHelper is BaseScript, OperationHelper {
    function deployVaultManager() internal returns (address, address) {
        VaultCrossChainManagerUpgradeable vaultManager = new VaultCrossChainManagerUpgradeable();
        OrderlyProxy proxy = new OrderlyProxy(address(vaultManager), bytes(""));
        VaultCrossChainManagerUpgradeable(payable(proxy)).initialize();
        return (address(vaultManager), address(proxy));
    }

    function deployProxyOnly(address impl) internal returns (address) {
        OrderlyProxy proxy = new OrderlyProxy(impl, bytes(""));
        return address(proxy);
    }

    function initializeOnly(address proxy) internal {
        VaultCrossChainManagerUpgradeable(payable(proxy)).initialize();
    }

    function deployNewVaultManager() internal returns (address) {
        VaultCrossChainManagerUpgradeable vaultManager = new VaultCrossChainManagerUpgradeable();
        return address(vaultManager);
    }

    function deployLedgerManager() internal returns (address, address) {
        LedgerCrossChainManagerUpgradeable vaultManager = new LedgerCrossChainManagerUpgradeable();
        OrderlyProxy proxy = new OrderlyProxy(address(vaultManager), bytes(""));
        LedgerCrossChainManagerUpgradeable(payable(proxy)).initialize();
        return (address(vaultManager), address(proxy));
    }

    function deployNewLedgerManager() internal returns (address) {
        LedgerCrossChainManagerUpgradeable ledgerManager = new LedgerCrossChainManagerUpgradeable();
        return address(ledgerManager);
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
        // print address and chain id
        console.log("managerProxy: ", managerProxy);
        console.log("chainId: ", getChainId(network));
        ICrossChainManager(payable(managerProxy)).setChainId(getChainId(network));
    }

    function setVaultAddress(address vaultManagerProxy, address vaultAddress) internal {
        // // debug info
        // uint256 ledgerChainId = VaultCrossChainManagerUpgradeable(payable(vaultManagerProxy)).ledgerChainId();
        // uint256 chainId = VaultCrossChainManagerUpgradeable(payable(vaultManagerProxy)).chainId();
        // console.log("ledger Chain Id: ", ledgerChainId);
        // console.log("vault Chain Id: ", chainId);
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
