pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "./RebalanceSetup.t.sol";

contract RebalanceTest is Test, RebalanceSetup {


    function setUp() public {
        deployVaultLedger();
        setupVaultLedger();
    }

    function test_rebalanceBurn() public {
        address(_srcRelayProxy).call{value: 1 ether}("");
        address(_dstRelayProxy).call{value: 1 ether}("");
        ledger.sendTestRebalanceBurn(_ledgerChainId, _vaultChainId);
    }

    function test_rebalanceMint() public {
        address(_srcRelayProxy).call{value: 1 ether}("");
        address(_dstRelayProxy).call{value: 1 ether}("");
        ledger.sendTestRebalanceMint(_ledgerChainId, _vaultChainId);
    }

  
}