// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../baseScripts/BaseScript.s.sol";
import "../baseScripts/ConfigHelper.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainRelayProxy.sol";

contract DeployRelay is BaseScript, ConfigHelper {

    using StringUtils for string;

    // variable order must be alphabetical
    struct DeployRelayConfig {
        string env;
        string[] networks;
    }

    function run() external {
        bytes memory encodedData = getConfigFileData("DEPLOY_RELAY_CONFIG_FILE");
        DeployRelayConfig memory config = abi.decode(encodedData, (DeployRelayConfig));
        for (uint i = 0; i < config.networks.length; i++) {
            string memory network = config.networks[i];
            deployRelay(network, config.env);
        }
    }

    function deployRelay(string memory network, string memory env) internal {
        console.log("network: ", network);

        uint256 pk = getPrivateKey(network);
        
        vmSelectRpcAndBroadcast(network);

        CrossChainRelayUpgradeable relay = new CrossChainRelayUpgradeable();
        console.log("deployed relay address: ", address(relay));
        CrossChainRelayProxy relayProxy = new CrossChainRelayProxy(address(relay), bytes(""));
        console.log("deployed relay proxy address: ", address(relayProxy));
        CrossChainRelayUpgradeable relayUpgradeable = CrossChainRelayUpgradeable(payable(address(relayProxy)));
        address lzEndpoint = getLzEndpoint(network); 
        console.log("lzEndpoint: ", lzEndpoint);
        relayUpgradeable.initialize(lzEndpoint);

        console.log("network: ", network);

        string memory deploySaveFile = vm.envString("DEPLOY_RELAY_SAVE_FILE");
        writeToJsonFileByKey(vm.toString(address(relayProxy)), deploySaveFile, env, network, "proxy");
        writeToJsonFileByKey(vm.toString(address(relay)), deploySaveFile, env, network, "relay");
        writeToJsonFileByKey(vm.toString(vm.addr(pk)), deploySaveFile, env, network, "owner");

        vm.stopBroadcast();
    }

}
