// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../baseScripts/BaseScript.s.sol";
import "../baseScripts/ConfigHelper.s.sol";
import "../contracts/LedgerCrossChainManagerUpgradeable.sol";
import "../contracts/CrossChainManagerProxy.sol";
import "../contracts/VaultCrossChainManagerUpgradeable.sol";

contract DeployCCManager is BaseScript, ConfigHelper {
    using StringUtils for string;

    // variable order must be alphabetical
    struct DeployCCManagerConfig {
        string env;
        string ledgerNetwork;
        string vaultNetwork;
    }

    function run() external {
        bytes memory encodedData = getConfigFileData("DEPLOY_CCMANAGER_CONFIG_FILE");
        DeployCCManagerConfig memory config = abi.decode(encodedData, (DeployCCManagerConfig));
        console.log("vaultNetwork: ", config.vaultNetwork);
        console.log("ledgerNetwork: ", config.ledgerNetwork);
        console.log("env: ", config.env);
        deployLedger(config.ledgerNetwork, config.env);
        deployVault(config.vaultNetwork, config.env);
    }

    function deployLedger(string memory network, string memory env) internal {
        console.log("network: ", network);

        uint256 pk = getPrivateKey(network);

        vmSelectRpcAndBroadcast(network);

        LedgerCrossChainManagerUpgradeable ledger = new LedgerCrossChainManagerUpgradeable();
        console.log("deployed ledger address: ", address(ledger));
        CrossChainManagerProxy ledgerProxy = new CrossChainManagerProxy(address(ledger), bytes(""));
        console.log("deployed ledger proxy address: ", address(ledgerProxy));
        LedgerCrossChainManagerUpgradeable ledgerUpgradeable =
            LedgerCrossChainManagerUpgradeable(payable(address(ledgerProxy)));
        ledgerUpgradeable.initialize();

        string memory deploySaveFile = vm.envString("DEPLOY_CCMANAGER_SAVE_FILE");
        writeToJsonFileByKey(vm.toString(address(ledgerProxy)), deploySaveFile, env, network, "proxy");
        writeToJsonFileByKey(vm.toString(address(ledger)), deploySaveFile, env, network, "manager");
        writeToJsonFileByKey(vm.toString(vm.addr(pk)), deploySaveFile, env, network, "owner");
        writeToJsonFileByKey("ledger", deploySaveFile, env, network, "role");

        vm.stopBroadcast();
    }

    function deployVault(string memory network, string memory env) internal {
        console.log("network: ", network);

        uint256 pk = getPrivateKey(network);

        vmSelectRpcAndBroadcast(network);

        VaultCrossChainManagerUpgradeable vault = new VaultCrossChainManagerUpgradeable();
        console.log("deployed vault address: ", address(vault));
        CrossChainManagerProxy vaultProxy = new CrossChainManagerProxy(address(vault), bytes(""));
        console.log("deployed vault proxy address: ", address(vaultProxy));
        VaultCrossChainManagerUpgradeable vaultUpgradeable =
            VaultCrossChainManagerUpgradeable(payable(address(vaultProxy)));
        vaultUpgradeable.initialize();

        string memory deploySaveFile = vm.envString("DEPLOY_CCMANAGER_SAVE_FILE");
        writeToJsonFileByKey(vm.toString(address(vaultProxy)), deploySaveFile, env, network, "proxy");
        writeToJsonFileByKey(vm.toString(address(vault)), deploySaveFile, env, network, "manager");
        writeToJsonFileByKey(vm.toString(vm.addr(pk)), deploySaveFile, env, network, "owner");
        writeToJsonFileByKey("vault", deploySaveFile, env, network, "role");

        vm.stopBroadcast();
    }
}
