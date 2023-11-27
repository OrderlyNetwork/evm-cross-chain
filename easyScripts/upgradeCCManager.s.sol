// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "../contracts/LedgerCrossChainManagerUpgradeable.sol";
import "../contracts/CrossChainManagerProxy.sol";
import "../contracts/VaultCrossChainManagerUpgradeable.sol";

contract DeployCCManager is BaseScript, ConfigHelper {
    using StringUtils for string;

    // variable order must be alphabetical
    struct UpgradeCCManagerConfig {
        string env;
        string ledgerNetwork;
        uint256 upgradeLedger;
        uint256 upgradeVault;
        string vaultNetwork;
    }

    function run() external {
        bytes memory encodedData = getConfigFileData("UPGRADE_CCMANAGER_CONFIG_FILE");
        UpgradeCCManagerConfig memory config = abi.decode(encodedData, (UpgradeCCManagerConfig));

        // logging everything in function call
        // check before you wreck
        console.log("vaultNetwork: ", config.vaultNetwork);
        console.log("ledgerNetwork: ", config.ledgerNetwork);
        console.log("upgradeLedger: ", config.upgradeLedger);
        console.log("upgradeVault: ", config.upgradeVault);
        console.log("env: ", config.env);

        CCManagerDeployData memory ledgerDeployData = getCCManagerDeployData(config.env, config.ledgerNetwork);

        CCManagerDeployData memory vaultDeployData = getCCManagerDeployData(config.env, config.vaultNetwork);
        if (config.upgradeLedger == 1) {
            upgradeLedger(config.ledgerNetwork, ledgerDeployData.proxy, ledgerDeployData.owner, config.env);
        }
        if (config.upgradeVault == 1) {
            upgradeVault(config.vaultNetwork, vaultDeployData.proxy, vaultDeployData.owner, config.env);
        }
    }

    function upgradeLedger(string memory network, address managerProxy, address owner, string memory env) internal {
        console.log("network: ", network);

        uint256 pk = getPrivateKey(network);
        require(owner == vm.addr(pk), "owner must be the same as the previous one");

        vmSelectRpcAndBroadcast(network);

        LedgerCrossChainManagerUpgradeable ledger = new LedgerCrossChainManagerUpgradeable();
        console.log("deployed new ledger cc manager address: ", address(ledger));
        LedgerCrossChainManagerUpgradeable ledgerProxy = LedgerCrossChainManagerUpgradeable(payable(managerProxy));
        console.log("ledger proxy address: ", address(ledgerProxy));

        ledgerProxy.upgradeTo(address(ledger));

        writeCCManagerDeployData(env, network, "manager", vm.toString(address(ledger)));

        vm.stopBroadcast();
    }

    function upgradeVault(string memory network, address managerProxy, address owner, string memory env) internal {
        console.log("network: ", network);

        uint256 pk = getPrivateKey(network);
        require(owner == vm.addr(pk), "owner must be the same as the previous one");

        vmSelectRpcAndBroadcast(network);

        VaultCrossChainManagerUpgradeable vault = new VaultCrossChainManagerUpgradeable();
        console.log("deployed new vault cc manager address: ", address(vault));
        VaultCrossChainManagerUpgradeable vaultProxy = VaultCrossChainManagerUpgradeable(payable(managerProxy));
        console.log("vault proxy address: ", address(vaultProxy));

        vaultProxy.upgradeTo(address(vault));

        writeCCManagerDeployData(env, network, "manager", vm.toString(address(vault)));

        vm.stopBroadcast();
    }
}
