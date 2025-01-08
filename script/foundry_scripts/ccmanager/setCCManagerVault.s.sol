// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/foundry_scripts/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/CCManagerHelper.s.sol";
import "evm-cross-chain/contracts/VaultCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/LedgerCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/OrderlyProxy.sol";
import "evm-cross-chain/contracts/interface/ICrossChainManager.sol";

contract SetCCManagerVault is BaseScript, ConfigHelper, CCManagerHelper {
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_setCCManagerVault_env");
        string memory network = vm.envString("FS_setCCManagerVault_network");

        CCManagerDeployData memory managerData = getCCManagerDeployData(env, network);

        address vault = getVaultAddress(env, network);

        console.log("[SetCCManagerVault]vault address: ", vault);

        vmSelectRpcAndBroadcast(env, network);

        console.log("[SetCCManagerVault]proxy: ", managerData.proxy);

        setVaultAddress(managerData.proxy, vault);

        vm.stopBroadcast();
    }
}
