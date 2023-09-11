// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../baseScripts/BaseScript.s.sol";
import "../baseScripts/ConfigHelper.s.sol";
import "../baseScripts/RelayHelper.s.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainRelayProxy.sol";

contract TransferNativeToken is BaseScript, ConfigHelper, RelayHelper {
    function run() external {
        string memory network = vm.envString("FS_transferNativeToken_network");
        string memory to = vm.envString("FS_transferNativeToken_to");
        uint256 memory amount = vm.env("FS_transferNativeToken_amount");

        console.log("[TransferNativeToken]to: ", to);
        console.log("[TransferNativeToken]network: ", network);
        console.log("[TransferNativeToken]amount: ", amount);

        vmSelectRpcAndBroadcast(network);

        // transfer by call
        transferNativeToken(to, amount);

        vm.stopBroadcast();
    }
}
