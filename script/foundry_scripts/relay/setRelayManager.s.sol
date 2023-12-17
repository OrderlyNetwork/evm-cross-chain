// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/RelayHelper.s.sol";
import "evm-cross-chain/contracts/CrossChainRelayUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainRelayProxy.sol";

contract SetRelayManager is BaseScript, ConfigHelper, RelayHelper {
    function run() external {
        string memory env = vm.envString("FS_setRelayManager_env");
        string memory network = vm.envString("FS_setRelayManager_network");

        console.log("[SetRelayManager]env: ", env);
        console.log("[SetRelayManager]network: ", network);

        RelayDeployData memory relayData = getRelayDeployData(env, network);
        CCManagerDeployData memory managerData = getCCManagerDeployData(env, network);

        console.log("[SetRelayManager]relay: ", relayData.proxy);
        console.log("[SetRelayManager]manager: ", managerData.proxy);

        vmSelectRpcAndBroadcast(network);

        setRelayManager(relayData.proxy, managerData.proxy);

        vm.stopBroadcast();
    }
}
