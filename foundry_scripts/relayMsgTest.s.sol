// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../baseScripts/BaseScript.s.sol";
import "../baseScripts/ConfigHelper.s.sol";
import "../baseScripts/RelayHelper.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainRelayProxy.sol";

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

        vmSelectRpcAndBroadcast(srcNetwork);

        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(relayData.proxy));

        relay.pingPong(dstChainId);

        vm.stopBroadcast();
    }
}
