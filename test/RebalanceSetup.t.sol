pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../contracts/test/VaultMock.sol";
import "../contracts/test/LedgerMock.sol";
import "./CrossChainManagerSetup.t.sol";

contract RebalanceSetup is Test, CrossChainManagerSetup {
    VaultMock public vault;
    LedgerMock public  ledger;

    function deployVaultLedger() public {
        deployCrossChainManager();
        setupCrossChainManager();
        vault = new VaultMock();
        ledger = new LedgerMock();
    }

    function setupVaultLedger() public {
        _ledgerManagerProxy.setLedger(address(ledger));
        _vaultManagerProxy.setVault(address(vault));

        ledger.setCrossChainManager(address(_ledgerManagerProxy));
        vault.setCrossChainManager(address(_vaultManagerProxy));
    }

}