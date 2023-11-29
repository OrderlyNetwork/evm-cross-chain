// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/RelayHelper.s.sol";
import "evm-cross-chain/contracts/CrossChainRelayUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainRelayProxy.sol";

contract SetCrossChainFee is BaseScript, ConfigHelper, RelayHelper {
    function run() external {
        string memory env = vm.envString("FS_setCrossChainFee_env");
        string memory network = vm.envString("FS_setCrossChainFee_network");
        string memory method = vm.envString("FS_setCrossChainFee_ccmethod");
        uint256 fee = vm.envUint("FS_setCrossChainFee_fee");

        console.log("[setCrossChainFee]env: ", env);
        console.log("[setCrossChainFee]network: ", network);
        console.log("[setCrossChainFee]method: ", method);
        console.log("[setCrossChainFee]fee: ", fee);

        RelayDeployData memory relayData = getRelayDeployData(env, network);
        vmSelectRpcAndBroadcast(network);

        setCrossChainFee(relayData.proxy, method, fee);

        vm.stopBroadcast();
    }
}
