// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../baseScripts/BaseScript.s.sol";
import "../baseScripts/ConfigHelper.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainRelayProxy.sol";

contract SetupRelay is BaseScript, ConfigHelper {

    using StringUtils for string;

    // variable order must be alphabetical
    struct SetupRelayConfig {
        string env;
        string network1;
        string network2;
    }

    function run() external {
        bytes memory encodedData = getConfigFileData("SETUP_RELAY_CONFIG_FILE");
        SetupRelayConfig memory config = abi.decode(encodedData, (SetupRelayConfig));

        RelayDeployData memory network1DeployData = getRelayDeployData(config.env, config.network1);
        RelayDeployData memory network2DeployData = getRelayDeployData(config.env, config.network2);

        setupRelay(config.network1, network1DeployData.proxy, config.network2, network2DeployData.proxy);
        setupRelay(config.network2, network2DeployData.proxy, config.network1, network1DeployData.proxy);

    }

    function setupRelay(string memory srcNetwork, address srcProxy, string memory dstNetwork, address dstProxy) internal {
        console.log("srcNetwork: ", srcNetwork);
        console.log("dstNetwork: ", dstNetwork);

        vmSelectRpcAndBroadcast(srcNetwork);

        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(srcProxy));
        // 1. transfer token
        srcProxy.call{value: 2 ether}("");
        // 2. add chain ID mapping
        relay.addChainIdMapping(getChainId(srcNetwork), getLzChainId(srcNetwork));
        relay.addChainIdMapping(getChainId(dstNetwork), getLzChainId(dstNetwork));
        // 3. set src chain id
        relay.setSrcChainId(getChainId(srcNetwork));
        // 4. set trusted remote
        bytes memory remoteAndLocal = abi.encodePacked(dstProxy, dstProxy);
        relay.setTrustedRemote(getLzChainId(dstNetwork), remoteAndLocal);

        vm.stopBroadcast();
    }

}
