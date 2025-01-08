// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/foundry_scripts/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/RelayHelper.s.sol";
import "evm-cross-chain/contracts/CrossChainRelayUpgradeable.sol";
import "evm-cross-chain/contracts/OrderlyProxy.sol";

contract DeployNewRelayImpl is BaseScript, ConfigHelper, RelayHelper {
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_deployNewRelayImpl_env");
        string memory network = vm.envString("FS_deployNewRelayImpl_network");
        bool broadcast = vm.envBool("FS_deployNewRelayImpl_broadcast");

        vmSelectRpcAndBroadcast(env, network);

        address relay  = deployNewRelayImpl();

        vm.stopBroadcast();

        console.log("[deployNewRelayImpl] Relay deployed at address: %s", relay);

        if (broadcast) {
            console.log("[deployNewRelayImpl] write relay deployment data to json file...");
            writeRelayDeployData(env, network, "relay", vm.toString(relay));
        }
    }
}
