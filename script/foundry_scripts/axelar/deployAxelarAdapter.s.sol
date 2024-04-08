// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "evm-cross-chain/script/baseScripts/AxelarHelper.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";

contract DeployAxelarAdapter is BaseScript, ConfigHelper, AxelarHelper{
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_deployAxelarAdapter_env");
        string memory network = vm.envString("FS_deployAxelarAdapter_network");
        bool broadcast = vm.envBool("FS_deployAxelarAdapter_broadcast");

        vmSelectRpcAndBroadcast(network);
        // vm.startBroadcast(getPrivateKey(network));

        (address adapter, address proxy) = deployAxelarAdapter();

        vm.stopBroadcast();

        console.log("[deployAxelarAdapter] Adapter deployed at address: %s", adapter);
        console.log("[deployAxelarAdapter] Proxy deployed at address: %s", proxy);

        if (broadcast) {
            console.log("[deployAxelarAdapter] write axelar adapter deployment data to json file...");
            // writeRelayDeployData(env, network, relay, proxy, vm.addr(getPrivateKey(network)));
        }
    }
}
