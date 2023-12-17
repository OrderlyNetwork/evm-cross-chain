// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/RelayHelper.s.sol";
import "evm-cross-chain/contracts/CrossChainRelayUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainRelayProxy.sol";

contract UpgradeRelay is BaseScript, ConfigHelper, RelayHelper {
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_upgradeRelay_env");
        string memory network = vm.envString("FS_upgradeRelay_network");
        bool broadcast = vm.envBool("FS_upgradeRelay_broadcast");

        console.log("[UpgradeRelay]env: ", env);
        console.log("[UpgradeRelay]network: ", network);
        console.log("[UpgradeRelay]broadcast: ", broadcast);

        RelayDeployData memory relayData = getRelayDeployData(env, network);
        vmSelectRpcAndBroadcast(network);
        address newRelay = upgradeRelay(relayData.proxy);
        vm.stopBroadcast();

        console.log("[UpgradeRelay]newRelay: ", newRelay);

        if (broadcast) {
            writeRelayDeployData(env, network, "relay", vm.toString(newRelay));
        }
    }
}
