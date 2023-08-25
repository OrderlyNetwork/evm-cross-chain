// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../baseScripts/BaseScript.s.sol";
import "../baseScripts/ConfigHelper.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainRelayProxy.sol";
import "../contracts/layerzero/interfaces/ILayerZeroEndpoint.sol";

contract CheckPayload is BaseScript, ConfigHelper {

    using StringUtils for string;

    // variable order must be alphabetical
    struct CheckPayloadConfig {
        string dstNetwork;
        string env;
        string srcNetwork;
    }

    function run() external {
        bytes memory encodedData = getConfigFileData("CHECK_LZ_PAYLOAD_STORE_CONFIG_FILE");
        CheckPayloadConfig memory config = abi.decode(encodedData, (CheckPayloadConfig));

        console.log("network1: ", config.dstNetwork);
        console.log("network2: ", config.srcNetwork);

        RelayDeployData memory network1RelayData = getRelayDeployData(config.env, config.srcNetwork);
        RelayDeployData memory network2RelayData = getRelayDeployData(config.env, config.dstNetwork);

        address network1Endpoint = getLzEndpoint(config.srcNetwork);
        address network2Endpoint = getLzEndpoint(config.dstNetwork);

        console.log("network1RelayData.proxy: ", network1RelayData.proxy);
        console.log("network2RelayData.proxy: ", network2RelayData.proxy);
        console.log("network1Endpoint: ", network1Endpoint);
        console.log("network2Endpoint: ", network2Endpoint);

        checkPayload(network1Endpoint, network1RelayData.proxy, network2RelayData.proxy, getLzChainId(config.srcNetwork));
        checkPayload(network2Endpoint, network2RelayData.proxy, network1RelayData.proxy, getLzChainId(config.dstNetwork));

    }

    function checkPayload(address endpoint, address srcUA, address dstUA, uint16 srcChainId) internal view {
        bytes memory path = abi.encodePacked(srcUA, dstUA);

        bool has = ILayerZeroEndpoint(endpoint).hasStoredPayload(srcChainId, path);

        if (has) {
            console.log("stored payload found for UA: ", srcUA);
        } else {
            console.log("no stored payload found for UA: ", srcUA);
        }

    }

}
