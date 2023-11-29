// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/RelayHelper.s.sol";
import "evm-cross-chain/contracts/CrossChainRelayUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainRelayProxy.sol";

contract SetRelayTrustedRemote is BaseScript, ConfigHelper, RelayHelper {
    function run() external {
        string memory env = vm.envString("FS_setRelayTrustedRemote_env");
        string memory srcNetwork = vm.envString("FS_setRelayTrustedRemote_srcNetwork");
        string memory dstNetwork = vm.envString("FS_setRelayTrustedRemote_dstNetwork");

        console.log("[setRelayTrustedRemote]env: ", env);
        console.log("[setRelayTrustedRemote]src network: ", srcNetwork);
        console.log("[setRelayTrustedRemote]dst network: ", dstNetwork);

        RelayDeployData memory srcRelayData = getRelayDeployData(env, srcNetwork);
        RelayDeployData memory dstRelayData = getRelayDeployData(env, dstNetwork);
        vmSelectRpcAndBroadcast(srcNetwork);

        setRelayLzTrustedRemote(srcRelayData.proxy, dstRelayData.proxy, dstNetwork);

        vm.stopBroadcast();
    }
}
