// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/CCManagerHelper.s.sol";
import "evm-cross-chain/contracts/VaultCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/LedgerCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainManagerProxy.sol";
import "evm-cross-chain/contracts/interface/ICrossChainManager.sol";

contract DeployCCManager is BaseScript, ConfigHelper, CCManagerHelper {
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_deployCCManager_env");
        string memory network = vm.envString("FS_deployCCManager_network");
        string memory role = vm.envString("FS_deployCCManager_role");
        bool broadcast = vm.envBool("FS_deployCCManager_broadcast");

        vmSelectRpcAndBroadcast(network);

        (address manager, address proxy) = deployManager(role);

        vm.stopBroadcast();

        if (broadcast) {
            console.log("[DeployCCManager] write cc manager deployment data to json file...");
            writeCCManagerDeployData(env, network, role, manager, proxy, vm.addr(getPrivateKey(network)));
        }
    }

    function deployManager(string memory role) internal returns (address, address) {
        if (role.compare("vault")) {
            return deployVaultManager();
        } else if (role.compare("ledger")) {
            return deployLedgerManager();
        } else {
            revert("[DeployCCManager] wrong role of manager");
        }
    }
}
