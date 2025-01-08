// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/foundry_scripts/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/RelayHelper.s.sol";
import "evm-cross-chain/contracts/CrossChainRelayUpgradeable.sol";
import "evm-cross-chain/contracts/OrderlyProxy.sol";

contract SetEndpoint is BaseScript, ConfigHelper, RelayHelper {
    function run() external {
        string memory env = vm.envString("FS_setEndpoint_env");
        string memory network = vm.envString("FS_setEndpoint_network");

        console.log("[setEndpoint]env: ", env);
        console.log("[setEndpoint]network: ", network);

        RelayDeployData memory relayData = getRelayDeployData(env, network);
        vmSelectRpcAndBroadcast(env, network);

        setEndpoint(relayData.proxy, network);

        vm.stopBroadcast();
    }
}
