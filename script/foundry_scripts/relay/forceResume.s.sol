// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/RelayHelper.s.sol";
import "evm-cross-chain/contracts/CrossChainRelayUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainRelayProxy.sol";

contract ForceResume is BaseScript, ConfigHelper, RelayHelper {
    function run() external {
        string memory env = vm.envString("FS_forceResume_env");
        string memory network = vm.envString("FS_forceResume_network");
        uint256 lzChainId = vm.envUint("FS_forceResume_lzChainId");
        bytes memory path = vm.envBytes("FS_forceResume_path");

        console.log("[forceResume]env: ", env);
        console.log("[forceResume]network: ", network);

        RelayDeployData memory relayData = getRelayDeployData(env, network);
        vmSelectRpcAndBroadcast(network);

        forceResume(relayData.proxy, uint16(lzChainId), path);

        vm.stopBroadcast();
    }
}
