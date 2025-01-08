// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/foundry_scripts/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/RelayHelper.s.sol";
import "evm-cross-chain/contracts/CrossChainRelayUpgradeable.sol";
import "evm-cross-chain/contracts/OrderlyProxy.sol";

contract SendPingPong is BaseScript, ConfigHelper, RelayHelper {
    function run() external {
        string memory env = vm.envString("FS_sendPingPong_env");
        string memory network = vm.envString("FS_sendPingPong_network");
        string memory dstNetwork = vm.envString("FS_sendPingPong_dstNetwork");

        console.log("[sendPingPong]env: ", env);
        console.log("[sendPingPong]network: ", network);

        RelayDeployData memory relayData = getRelayDeployData(env, network);
        vmSelectRpcAndBroadcast(env, network);

        sendPingPong(relayData.proxy, dstNetwork);

        vm.stopBroadcast();
    }
}
