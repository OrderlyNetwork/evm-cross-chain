// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainRelayProxy.sol";
import "../contracts/layerzero/interfaces/ILayerZeroEndpoint.sol";

contract RetryPayload is BaseScript, ConfigHelper {
    using StringUtils for string;

    // variable order must be alphabetical
    struct RetryPayloadConfig {
        bytes data;
        string network;
    }

    function run() external {
        bytes memory encodedData = getConfigFileData("RETRY_LZ_PAYLOAD_STORE_CONFIG_FILE");
        RetryPayloadConfig memory config = abi.decode(encodedData, (RetryPayloadConfig));

        console.log("network: ", config.network);

        address lzEndpoint = getLzEndpoint(config.network);

        checkPayload(config.network, lzEndpoint, config.data);
    }

    function checkPayload(string memory network, address endpoint, bytes memory data) internal {
        vmSelectRpcAndBroadcast(network);
        (uint16 srcChainId, bytes memory srcAddress,,, bytes memory payload,) =
            abi.decode(data, (uint16, bytes, address, uint64, bytes, bytes));

        console.log("retry payload...");
        ILayerZeroEndpoint(endpoint).retryPayload(srcChainId, srcAddress, payload);

        vm.stopBroadcast();
    }
}
