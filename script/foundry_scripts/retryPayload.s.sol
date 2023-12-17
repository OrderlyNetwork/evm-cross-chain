// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/contracts/CrossChainRelayUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainRelayProxy.sol";
import "evm-cross-chain/contracts/layerzero/interfaces/ILayerZeroEndpoint.sol";

contract RetryPayload is BaseScript, ConfigHelper {
    using StringUtils for string;

    function run() external {
        string memory network = vm.envString("FS_retryPayload_network");
        bytes memory data = vm.envBytes("FS_retryPayload_data");

        address endpoint = getLzEndpoint(network);

        vmSelectRpcAndBroadcast(network);
        (uint16 srcChainId, bytes memory srcAddress,,, bytes memory payload,) =
            abi.decode(data, (uint16, bytes, address, uint64, bytes, bytes));

        console.log("retry payload...");
        ILayerZeroEndpoint(endpoint).retryPayload(srcChainId, srcAddress, payload);

        vm.stopBroadcast();
    }
}
