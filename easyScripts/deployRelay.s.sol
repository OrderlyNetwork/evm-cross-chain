// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../baseScripts/BaseScript.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainRelayProxy.sol";

contract DeployRelay is BaseScript {

    using StringUtils for string;

    struct DeployRelayConfig {
        string[] networks;
    }

    function run() external {
        string memory configFile = vm.envString("DEPLOY_RELAY_CONFIG_FILE");
        string memory fileData = vm.readFile(configFile);
        bytes memory encodedData = vm.parseJson(fileData);
        DeployRelayConfig memory config = abi.decode(encodedData, (DeployRelayConfig));
        for (uint i = 0; i < config.networks.length; i++) {
            string memory network = config.networks[i];
            deployRelay(network);
        }
    }

    function deployRelay(string memory network) internal {
        console.log("network: ", network);
        string memory rpcUrl = getRpcUrl(network);
        uint256 pk = getPrivateKey(network);
        vm.createSelectFork(rpcUrl); 
        vm.startBroadcast(pk);
        CrossChainRelayUpgradeable relay = new CrossChainRelayUpgradeable();
        console.log("deployed relay address: ", address(relay));
        CrossChainRelayProxy relayProxy = new CrossChainRelayProxy(address(relay), bytes(""));
        console.log("deployed relay proxy address: ", address(relayProxy));
        CrossChainRelayUpgradeable relayUpgradeable = CrossChainRelayUpgradeable(payable(address(relayProxy)));
        address lzEndpoint = getLzEndpoint(network); 
        console.log("lzEndpoint: ", lzEndpoint);
        relayUpgradeable.initialize(lzEndpoint);

        console.log("network: ", network);

        // save the relay and relay proxy address
        string memory relayProxyAddressKey = network.formJsonKey().concat(string("proxy").formJsonKey());
        string memory relayAddressKey = network.formJsonKey().concat(string("relay").formJsonKey());
        string memory ownerKey = network.formJsonKey().concat(string("owner").formJsonKey());

        string memory deploySaveFile = "config/cross-chain-relay.json";
        vm.writeJson(vm.toString(address(relayProxy)), deploySaveFile, relayProxyAddressKey);
        vm.writeJson(vm.toString(address(relay)), deploySaveFile, relayAddressKey);
        vm.writeJson(vm.toString(vm.addr(pk)), deploySaveFile, ownerKey);

        vm.stopBroadcast();
    }

}
