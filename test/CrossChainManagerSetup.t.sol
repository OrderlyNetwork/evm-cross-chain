pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "./CrossChainRelaySetup.t.sol";
import "../contracts/LedgerCrossChainManagerUpgradeable.sol";
import "../contracts/VaultCrossChainManagerUpgradeable.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainManagerProxy.sol";

contract CrossChainManagerSetup is Test, CrossChainRelaySetup {
    LedgerCrossChainManagerUpgradeable _ledgerManagerProxy;
    VaultCrossChainManagerUpgradeable _vaultManagerProxy;
    LedgerCrossChainManagerUpgradeable _ledgerManagerImpl;
    VaultCrossChainManagerUpgradeable _vaultManagerImpl;

    function deployCrossChainManager() public {
        _ledgerManagerImpl = new LedgerCrossChainManagerUpgradeable();
        _vaultManagerImpl = new VaultCrossChainManagerUpgradeable();
        CrossChainManagerProxy ledgerManagerProxy = new CrossChainManagerProxy(address(_ledgerManagerImpl), bytes(""));
        CrossChainManagerProxy vaultManagerProxy = new CrossChainManagerProxy(address(_vaultManagerImpl), bytes(""));

        _ledgerManagerProxy = LedgerCrossChainManagerUpgradeable(address(ledgerManagerProxy));
        _vaultManagerProxy = VaultCrossChainManagerUpgradeable(address(vaultManagerProxy));

        _ledgerManagerProxy.initialize();
        _vaultManagerProxy.initialize();
    }

    function setupCrossChainManager() public {
        deployCrossChainRelay();
        setupCrossChainRelay();

        _vaultManagerProxy.setChainId(_vaultChainId);
        _vaultManagerProxy.setCrossChainRelay(address(_srcRelayProxy));
        _vaultManagerProxy.setLedgerCrossChainManager(_ledgerChainId, address(_ledgerManagerProxy));
        _ledgerManagerProxy.setChainId(_ledgerChainId);
        _ledgerManagerProxy.setCrossChainRelay(address(_dstRelayProxy));

        CrossChainRelayUpgradeable(payable(address(_srcRelayProxy))).setManagerAddress(address(_vaultManagerProxy));
        CrossChainRelayUpgradeable(payable(address(_dstRelayProxy))).setManagerAddress(address(_ledgerManagerProxy));
    }
}

contract CrossChainManagerFactory {
    function newLedgerCrossChainManager() public returns (address) {
        LedgerCrossChainManagerUpgradeable ledgerManager = new LedgerCrossChainManagerUpgradeable();
        CrossChainManagerProxy ledgerManagerProxy = new CrossChainManagerProxy(address(ledgerManager), bytes(""));
        LedgerCrossChainManagerUpgradeable(payable(address(ledgerManagerProxy))).initialize();
        return address(ledgerManagerProxy);
    }

    function newVaultCrossChainManager() public returns (address) {
        VaultCrossChainManagerUpgradeable vaultManager = new VaultCrossChainManagerUpgradeable();
        CrossChainManagerProxy vaultManagerProxy = new CrossChainManagerProxy(address(vaultManager), bytes(""));
        VaultCrossChainManagerUpgradeable(payable(address(vaultManagerProxy))).initialize();
        return address(vaultManagerProxy);
    }

    function transferOwner(address manager, address newOwner) public {
        OwnableUpgradeable(manager).transferOwnership(newOwner);
    }
}
