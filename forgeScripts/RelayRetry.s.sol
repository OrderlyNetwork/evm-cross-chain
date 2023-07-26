// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "./BaseScript.s.sol";
import "../contracts/layerzero/interfaces/ILayerZeroEndpoint.sol";

contract RelayRetry is BaseScript {
    function run() external {
        string memory network = vm.envString("CURRENT_NETWORK");
        vm.startBroadcast(getPrivateKey(network));
        retryLzCrossChain(network);
        vm.stopBroadcast();
    }

    function retryLzCrossChain(string memory network) internal {
        address endpoint = getLzEndpoint(network);
        bytes memory data = vm.envBytes("RETRY_PAYLOAD_RAW_DATA");
        ILayerZeroEndpoint endpointInstance = ILayerZeroEndpoint(payable(endpoint));
        (
            uint16 srcChainId,
            bytes memory srcAddress,
            address dstAddress,
            uint64 nonce,
            bytes memory payload,
            bytes memory reason
        ) = abi.decode(data, (uint16, bytes, address, uint64, bytes, bytes));
        endpointInstance.retryPayload(srcChainId, srcAddress, payload);
    }
}
