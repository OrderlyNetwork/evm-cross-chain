// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./BaseScript.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";

contract Transfer is BaseScript {
    function run() external {
        address to = vm.envAddress("TRANSFER_ADDRESS");
        uint256 amount = vm.envUint("TRANSFER_AMOUNT");
        string memory network = vm.envString("CURRENT_NETWORK");
        uint256 pk = getPrivateKey(network);
        vm.startBroadcast(pk);
        // transfer to to address using call{value: amount}("") and handle returns
        (bool success, ) = to.call{value: amount}("");
        if (!success) {
            revert("Transfer failed");
        }

        vm.stopBroadcast();
    }

}
