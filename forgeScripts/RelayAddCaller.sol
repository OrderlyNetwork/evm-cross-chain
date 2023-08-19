// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../baseScripts/BaseScript.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";

contract RelayAddManagerAsCaller is BaseScript {
    function run() external {
        string memory network = vm.envString("CURRENT_NETWORK");
        address relayProxyAddress = getRelayProxyAddress(network);
        address newCaller = vm.envAddress("NEW_CALLER");
        vm.startBroadcast(getPrivateKey(network));

        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(relayProxyAddress));
        relay.addCaller(newCaller);
        vm.stopBroadcast();
    }

}
