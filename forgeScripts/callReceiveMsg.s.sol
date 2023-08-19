// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./BaseScript.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/utils/OrderlyCrossChainMessage.sol";

contract CallReceiveMsg is BaseScript {
    function run() external {
        string memory network = vm.envString("CURRENT_NETWORK");
        address relayProxyAddress = getRelayProxyAddress(network);
        vm.startBroadcast(getPrivateKey(network));

        bytes memory codedata = vm.envBytes("RETRY_PAYLOAD_RAW_DATA");

        (OrderlyCrossChainMessage.MessageV1 memory data, bytes memory payload) = abi.decode(codedata, (OrderlyCrossChainMessage.MessageV1, bytes));

        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(relayProxyAddress));
        relay.receiveMessage(data, payload);
        vm.stopBroadcast();
    }

}
