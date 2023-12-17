// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/RelayHelper.s.sol";
import "evm-cross-chain/contracts/CrossChainRelayUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainRelayProxy.sol";

contract TransferNativeToken is BaseScript, ConfigHelper, RelayHelper {
    function run() external {
        string memory network = vm.envString("FS_transferNativeToken_network");
        address to = vm.envAddress("FS_transferNativeToken_to");
        uint256 amount = vm.envUint("FS_transferNativeToken_amount");

        console.log("[TransferNativeToken]to: ", to);
        console.log("[TransferNativeToken]network: ", network);
        console.log("[TransferNativeToken]amount: ", amount);

        vmSelectRpcAndBroadcast(network);

        // transfer by call
        transferNativeToken(to, amount);

        vm.stopBroadcast();
    }
}
