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

    function deployCrossChainManager() public {
        CrossChainManagerProxy ledgerManagerProxy =
            new CrossChainManagerProxy(address(new LedgerCrossChainManagerUpgradeable()), bytes(""));
        CrossChainManagerProxy vaultManagerProxy =
            new CrossChainManagerProxy(address(new VaultCrossChainManagerUpgradeable()), bytes(""));

        _ledgerManagerProxy = LedgerCrossChainManagerUpgradeable(address(ledgerManagerProxy));
        _vaultManagerProxy = VaultCrossChainManagerUpgradeable(address(vaultManagerProxy));

        _ledgerManagerProxy.initialize();
        _vaultManagerProxy.initialize();
    }

    function setupCrossChainManager() public {
        deployCrossChainRelay();
        setupCrossChainRelay();

        _vaultManagerProxy.setChainId(_srcChainId);
        _vaultManagerProxy.setCrossChainRelay(address(_srcRelayProxy));
        _vaultManagerProxy.setLedgerCrossChainManager(_dstChainId, address(_ledgerManagerProxy));
        _ledgerManagerProxy.setChainId(_dstChainId);
        _ledgerManagerProxy.setCrossChainRelay(address(_dstRelayProxy));

        CrossChainRelayUpgradeable(payable(address(_srcRelayProxy))).setManagerAddress(address(_vaultManagerProxy));
        CrossChainRelayUpgradeable(payable(address(_dstRelayProxy))).setManagerAddress(address(_ledgerManagerProxy));
    }
}
