// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/CCManagerHelper.s.sol";
import "evm-cross-chain/contracts/VaultCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/LedgerCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainManagerProxy.sol";
import "evm-cross-chain/contracts/interface/ICrossChainManager.sol";

contract DeployNewManagerImpl is BaseScript, ConfigHelper, CCManagerHelper {
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_deployNewManagerImpl_env");
        string memory network = vm.envString("FS_deployNewManagerImpl_network");
        string memory role = vm.envString("FS_deployNewManagerImpl_role");
        bool broadcast = vm.envBool("FS_deployNewManagerImpl_broadcast");

        vmSelectRpcAndBroadcast(network);

        address manager = deployManager(role);

        vm.stopBroadcast();

        if (broadcast) {
            console.log("[deployNewManagerImpl] write cc manager deployment data to json file...");
            writeCCManagerDeployData(env, network, "manager", vm.toString(manager));
        }
    }

    function deployManager(string memory role) internal returns (address) {
        if (role.compare("vault")) {
            return deployNewVaultManager();
        } else if (role.compare("ledger")) {
            return deployNewLedgerManager();
        } else {
            revert("[deployNewManagerImpl] wrong role of manager");
        }
    }
}
