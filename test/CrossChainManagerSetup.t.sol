pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "./CrossChainRelaySetup.t.sol";
import "../contracts/LedgerCrossChainManagerUpgradeable.sol";
import "../contracts/VaultCrossChainManagerUpgradeable.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/OrderlyProxy.sol";

contract DummyContract {
    // fallback that no reverts
    fallback() external {}
}

contract CrossChainManagerSetup is Test, CrossChainRelaySetup {
    LedgerCrossChainManagerUpgradeable _ledgerManagerProxy;
    VaultCrossChainManagerUpgradeable _vaultManagerProxy;
    LedgerCrossChainManagerUpgradeable _ledgerManagerImpl;
    VaultCrossChainManagerUpgradeable _vaultManagerImpl;

    function deployCrossChainManager() public {
        _ledgerManagerImpl = new LedgerCrossChainManagerUpgradeable();
        _vaultManagerImpl = new VaultCrossChainManagerUpgradeable();
        OrderlyProxy ledgerManagerProxy = new OrderlyProxy(address(_ledgerManagerImpl), bytes(""));
        OrderlyProxy vaultManagerProxy = new OrderlyProxy(address(_vaultManagerImpl), bytes(""));

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

        // set dummy contract as vault
        _vaultManagerProxy.setVault(address(new DummyContract()));
        _ledgerManagerProxy.setLedger(address(new DummyContract()));

        CrossChainRelayUpgradeable(payable(address(_srcRelayProxy))).setManagerAddress(address(_vaultManagerProxy));
        CrossChainRelayUpgradeable(payable(address(_dstRelayProxy))).setManagerAddress(address(_ledgerManagerProxy));
    }
}

contract CrossChainManagerFactory {
    function newLedgerCrossChainManager() public returns (address) {
        LedgerCrossChainManagerUpgradeable ledgerManager = new LedgerCrossChainManagerUpgradeable();
        OrderlyProxy ledgerManagerProxy = new OrderlyProxy(address(ledgerManager), bytes(""));
        LedgerCrossChainManagerUpgradeable(payable(address(ledgerManagerProxy))).initialize();
        return address(ledgerManagerProxy);
    }

    function newVaultCrossChainManager() public returns (address) {
        VaultCrossChainManagerUpgradeable vaultManager = new VaultCrossChainManagerUpgradeable();
        OrderlyProxy vaultManagerProxy = new OrderlyProxy(address(vaultManager), bytes(""));
        VaultCrossChainManagerUpgradeable(payable(address(vaultManagerProxy))).initialize();
        return address(vaultManagerProxy);
    }

    function transferOwner(address manager, address newOwner) public {
        OwnableUpgradeable(manager).transferOwnership(newOwner);
    }
}
