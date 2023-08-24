// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../baseScripts/BaseScript.s.sol";
import "../baseScripts/ConfigHelper.s.sol";
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

        RelayDeployData memory network1RelayData = getRelayDeployData(env, config.network1);
        RelayDeployData memory network2RelayData = getRelayDeployData(env, config.network2);

        CCManagerDeployData memory network1ManagerData = getCCManagerDeployData(env, config.network1);
        CCManagerDeployData memory network2ManagerData = getCCManagerDeployData(env, config.network2);

        setManager(config.network1, network1RelayData.proxy, network1ManagerData.manager);
        setManager(config.network2, network2RelayData.proxy, network2ManagerData.manager);

    }

    function setManager(string memory network, address relayAddress, address manager) internal {

        vmSelectRpcAndBroadcast(network);

        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(relayAddress));
        relay.setManagerAddress(manager);

        vm.stopBroadcast();
    }

}
