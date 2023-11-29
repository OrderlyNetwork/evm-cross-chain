// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/RelayHelper.s.sol";
import "evm-cross-chain/contracts/CrossChainRelayUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainRelayProxy.sol";

contract DeployRelay is BaseScript, ConfigHelper, RelayHelper {
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_deployRelay_env");
        string memory network = vm.envString("FS_deployRelay_network");
        bool broadcast = vm.envBool("FS_deployRelay_broadcast");

        // vmSelectRpcAndBroadcast(network);
        vm.startBroadcast(getPrivateKey(network));

        address lzEndpoint = getLzEndpoint(network);

        (address relay, address proxy) = deployRelay(lzEndpoint);

        vm.stopBroadcast();

        console.log("[DeployRelay] Relay deployed at address: %s", relay);
        console.log("[DeployRelay] Proxy deployed at address: %s", proxy);

        if (broadcast) {
            console.log("[DeployRelay] write relay deployment data to json file...");
            writeRelayDeployData(env, network, relay, proxy, vm.addr(getPrivateKey(network)));
        }
    }
}
