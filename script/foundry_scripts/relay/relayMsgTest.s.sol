// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/foundry_scripts/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/RelayHelper.s.sol";
import "evm-cross-chain/contracts/CrossChainRelayUpgradeable.sol";
import "evm-cross-chain/contracts/OrderlyProxy.sol";

contract RelayMsgTest is BaseScript, ConfigHelper, RelayHelper {
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_relayMsgTest_env");
        string memory srcNetwork = vm.envString("FS_relayMsgTest_srcNetwork");
        string memory dstNetwork = vm.envString("FS_relayMsgTest_dstNetwork");

        console.log("[UpgradeRelay]env: ", env);
        console.log("[UpgradeRelay]srcNetwork: ", srcNetwork);
        console.log("[UpgradeRelay]dstNetwork: ", dstNetwork);

        RelayDeployData memory relayData = getRelayDeployData(env, srcNetwork);
        uint256 dstChainId = getChainId(dstNetwork);

        vmSelectRpcAndBroadcast(env, srcNetwork);

        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(relayData.proxy));

        relay.pingPong(dstChainId);

        vm.stopBroadcast();
    }
}
