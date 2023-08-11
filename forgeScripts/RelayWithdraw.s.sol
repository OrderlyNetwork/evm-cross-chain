// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./BaseScript.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";

contract RelayRetry is BaseScript {
    function run() external {
        address relay = vm.envAddress("WITHDRAW_RELAY_ADDRESS");
        string memory network = vm.envString("CURRENT_NETWORK");
        uint256 pk = getPrivateKey(network);
        address accountAddress = vm.addr(pk);
        vm.startBroadcast(pk);
        withdraw(relay, accountAddress);
        vm.stopBroadcast();
    }

    function withdraw(address relayAddress, address to) internal {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(relayAddress));

        // balance of contract
        uint256 balance = relayAddress.balance;

        // withdraw
        relay.withdrawNativeToken(payable(to), balance);

    }
}
