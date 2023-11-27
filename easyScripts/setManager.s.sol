// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainRelayProxy.sol";

contract SetManager is BaseScript, ConfigHelper {

    using StringUtils for string;

    // variable order must be alphabetical
    struct SetManagerConfig {
        string env;
        string network1;
        string network2;
    }

    function run() external {
        bytes memory encodedData = getConfigFileData("SET_CCMANAGER_CONFIG_FILE");
        SetManagerConfig memory config = abi.decode(encodedData, (SetManagerConfig));

        console.log("network1: ", config.network1);
        console.log("network2: ", config.network2);

        RelayDeployData memory network1RelayData = getRelayDeployData(config.env, config.network1);
        RelayDeployData memory network2RelayData = getRelayDeployData(config.env, config.network2);

        CCManagerDeployData memory network1ManagerData = getCCManagerDeployData(config.env, config.network1);
        CCManagerDeployData memory network2ManagerData = getCCManagerDeployData(config.env, config.network2);

        console.log("network1RelayData.proxy: ", network1RelayData.proxy);
        console.log("network2RelayData.proxy: ", network2RelayData.proxy);
        console.log("network1ManagerData.proxy: ", network1ManagerData.proxy);
        console.log("network2ManagerData.proxy: ", network2ManagerData.proxy);

        setManager(config.network1, network1RelayData.proxy, network1ManagerData.proxy);
        setManager(config.network2, network2RelayData.proxy, network2ManagerData.proxy);

    }

    function setManager(string memory network, address relayAddress, address manager) internal {

        vmSelectRpcAndBroadcast(network);

        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(relayAddress));
        relay.setManagerAddress(manager);

        vm.stopBroadcast();
    }

}
