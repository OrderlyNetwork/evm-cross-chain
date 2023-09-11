// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../baseScripts/BaseScript.s.sol";
import "../baseScripts/ConfigHelper.s.sol";
import "../baseScripts/RelayHelper.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainRelayProxy.sol";

contract SetRelayChainId is BaseScript, ConfigHelper, RelayHelper {
    function run() external {
        string memory env = vm.envString("FS_setRelayChainId_env");
        string memory network = vm.envString("FS_setRelayChainId_network");

        console.log("[SetRelayChainId]env: ", env);
        console.log("[SetRelayChainId]network: ", network);

        RelayDeployData memory relayData = getRelayDeployData(env, network);
        vmSelectRpcAndBroadcast(network);

        setRelayChainId(relayData.proxy, network);

        vm.stopBroadcast();
    }
}
