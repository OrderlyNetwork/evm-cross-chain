// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainRelayProxy.sol";

contract SetupRelay is BaseScript, ConfigHelper {
    using StringUtils for string;

    // variable order must be alphabetical
    struct SetRemoteConfig {
        string env;
        string network1;
        string network2;
    }

    function run() external {
        bytes memory encodedData = getConfigFileData("SET_REMOTE_CONFIG_FILE");
        SetRemoteConfig memory config = abi.decode(encodedData, (SetRemoteConfig));

        RelayDeployData memory deployData1 = getRelayDeployData(config.env, config.network1);
        RelayDeployData memory deployData2 = getRelayDeployData(config.env, config.network2);

        uint16 net1ChainId = getLzChainId(config.network1);
        uint16 net2ChainId = getLzChainId(config.network2);

        vmSelectRpcAndBroadcast(config.network1);
        CrossChainRelayUpgradeable relay1 = CrossChainRelayUpgradeable(payable(deployData1.proxy));
        relay1.setTrustedRemote(net2ChainId, abi.encodePacked(deployData2.proxy, deployData1.proxy));
        vm.stopBroadcast();

        vmSelectRpcAndBroadcast(config.network2);
        CrossChainRelayUpgradeable relay2 = CrossChainRelayUpgradeable(payable(deployData2.proxy));
        relay2.setTrustedRemote(net1ChainId, abi.encodePacked(deployData1.proxy, deployData2.proxy));
        vm.stopBroadcast();
    }
}
