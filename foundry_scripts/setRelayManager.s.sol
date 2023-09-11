// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../baseScripts/BaseScript.s.sol";
import "../baseScripts/ConfigHelper.s.sol";
import "../baseScripts/RelayHelper.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainRelayProxy.sol";

contract SetRelayManager is BaseScript, ConfigHelper, RelayHelper {
    function run() external {
        string memory env = vm.envString("FS_setRelayManager_env");
        string memory network = vm.envString("FS_setRelayManager_network");

        console.log("[SetRelayManager]env: ", env);
        console.log("[SetRelayManager]network: ", network);

        RelayDeployData memory relayData = getRelayDeployData(env, network);
        vmSelectRpcAndBroadcast(network);

        setRelayManager(relayData.proxy, network);

        vm.stopBroadcast();
    }
}
