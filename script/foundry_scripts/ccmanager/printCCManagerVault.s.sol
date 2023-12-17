// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/CCManagerHelper.s.sol";
import "evm-cross-chain/contracts/VaultCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/LedgerCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainManagerProxy.sol";
import "evm-cross-chain/contracts/interface/ICrossChainManager.sol";

contract PrintCCManagerVault is BaseScript, ConfigHelper, CCManagerHelper {
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_printCCManagerVault_env");
        string memory network = vm.envString("FS_printCCManagerVault_network");
        CCManagerDeployData memory managerData = getCCManagerDeployData(env, network);

        vmSelectRpcAndBroadcast(network);

        VaultCrossChainManagerUpgradeable vaultManager = VaultCrossChainManagerUpgradeable(payable(managerData.proxy));

        // print everything on vaultManager
        // print chain Id
        console.log("chainId: ", vaultManager.chainId());
        // print vault address
        console.log("vault address: ", address(vaultManager.vault()));
        // print relay address
        console.log("relay address: ", address(vaultManager.crossChainRelay()));
        // print ledger chainId
        console.log("ledger chainId: ", vaultManager.ledgerChainId());
        // print ledger cc manager address
        console.log(
            "ledger cc manager address: ", address(vaultManager.ledgerCrossChainManagers(vaultManager.ledgerChainId()))
        );

        vm.stopBroadcast();
    }
}
