// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/foundry_scripts/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/foundry_scripts/baseScripts/RelayHelper.s.sol";
import "evm-cross-chain/contracts/CrossChainRelayUpgradeable.sol";
import "evm-cross-chain/contracts/OrderlyProxy.sol";

contract RelayInitializeOnly is BaseScript, ConfigHelper, RelayHelper {
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_relayInitializeOnly_env");
        string memory network = vm.envString("FS_relayInitializeOnly_network");

        RelayDeployData memory relayData = getRelayDeployData(env, network);

        address proxy = relayData.proxy;

        vmSelectRpcAndBroadcast(env, network);

        address lzEndpoint = getLzEndpoint(network);
        initializeOnly(proxy, lzEndpoint);

        vm.stopBroadcast();

    }
}
