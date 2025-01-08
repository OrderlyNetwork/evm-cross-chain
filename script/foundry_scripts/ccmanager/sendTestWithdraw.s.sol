// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/foundry_scripts/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/CCManagerHelper.s.sol";
import "evm-cross-chain/contracts/VaultCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/LedgerCrossChainManagerUpgradeable.sol";
import "evm-cross-chain/contracts/OrderlyProxy.sol";
import "evm-cross-chain/contracts/interface/ICrossChainManager.sol";

contract SendTestWithdraw is BaseScript, ConfigHelper, CCManagerHelper {
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_sendTestWithdraw_env");
        string memory network = vm.envString("FS_sendTestWithdraw_network");
        string memory toNetwork = vm.envString("FS_sendTestWithdraw_toNetwork");

        CCManagerDeployData memory managerData = getCCManagerDeployData(env, network);

        vmSelectRpcAndBroadcast(env, network);

        sendTestWithdraw(managerData.proxy, toNetwork);

        vm.stopBroadcast();
    }
}
