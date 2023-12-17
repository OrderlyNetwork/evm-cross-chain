// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/CCManagerHelper.s.sol";
import "evm-cross-chain/contracts/VaultCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/LedgerCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainManagerProxy.sol";
import "evm-cross-chain/contracts/interface/ICrossChainManager.sol";

contract UpgradeCCManager is BaseScript, ConfigHelper, CCManagerHelper {
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_upgradeCCManager_env");
        string memory network = vm.envString("FS_upgradeCCManager_network");
        string memory role = vm.envString("FS_upgradeCCManager_role");
        bool broadcast = vm.envBool("FS_upgradeCCManager_broadcast");

        CCManagerDeployData memory managerData = getCCManagerDeployData(env, network);

        vmSelectRpcAndBroadcast(network);

        address manager = upgradeManager(role, managerData.proxy);

        vm.stopBroadcast();

        if (broadcast) {
            console.log("[upgradeCCManager] write cc manager deployment data to json file...");
            writeCCManagerDeployData(env, network, "manager", vm.toString(manager));
        }
    }

    function upgradeManager(string memory role, address proxy) internal returns (address) {
        if (role.compare("vault")) {
            return upgradeVaultManager(proxy);
        } else if (role.compare("ledger")) {
            return upgradeLedgerManager(proxy);
        } else {
            revert("[upgradeCCManager] wrong role of manager");
        }
    }
}
