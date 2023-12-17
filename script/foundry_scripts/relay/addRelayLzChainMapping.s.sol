// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/RelayHelper.s.sol";
import "evm-cross-chain/contracts/CrossChainRelayUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainRelayProxy.sol";

contract AddRelayLzChainMapping is BaseScript, ConfigHelper, RelayHelper {
    using StringUtils for string;

    function run() external {
        string memory env = vm.envString("FS_addRelayLzChainMapping_env");
        string memory relayNetwork = vm.envString("FS_addRelayLzChainMapping_relayNetwork");
        string memory addNetwork = vm.envString("FS_addRelayLzChainMapping_addNetwork");

        console.log("[AddRelayLzChainMapping]env: ", env);
        console.log("[AddRelayLzChainMapping]relayNetwork: ", relayNetwork);
        console.log("[AddRelayLzChainMapping]addNetwork: ", addNetwork);

        RelayDeployData memory relayRelayData = getRelayDeployData(env, relayNetwork);

        vmSelectRpcAndBroadcast(relayNetwork);

        addRelayLzChainMapping(relayRelayData.proxy, addNetwork);

        vm.stopBroadcast();
    }
}
