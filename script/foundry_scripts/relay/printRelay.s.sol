// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/RelayHelper.s.sol";
import "evm-cross-chain/contracts/CrossChainRelayUpgradeable.sol";
import "evm-cross-chain/contracts/CrossChainRelayProxy.sol";

contract PrintRelay is BaseScript, ConfigHelper, RelayHelper {
    function run() external {
        string memory env = vm.envString("FS_printRelay_env");
        string memory network = vm.envString("FS_printRelay_network");
        string memory dstNetwork = vm.envString("FS_printRelay_dstNetwork");

        console.log("[PrintRelay]env: ", env);
        console.log("[PrintRelay]network: ", network);
        console.log("[PrintRelay]dstNetwork: ", dstNetwork);

        RelayDeployData memory relayData = getRelayDeployData(env, network);
        vmSelectRpcAndBroadcast(network);

        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(relayData.proxy));
        // print chain id
        console.log("chainId: ", relay._currentChainId());
        // print lz chain id mapping
        console.log("lz chain id mapping: ", getChainId(dstNetwork), relay._chainIdMapping(getChainId(dstNetwork)));
        console.log("lz chain id mapping: ", getChainId(network), relay._chainIdMapping(getChainId(network)));
        console.log(
            "lz chain id mapping: ", getLzChainId(dstNetwork), relay._lzChainIdMapping(getLzChainId(dstNetwork))
        );
        console.log("lz chain id mapping: ", getLzChainId(network), relay._lzChainIdMapping(getLzChainId(network)));
        // print trusted remoted
        console.log("trusted remote: ");
        console.logBytes(relay.trustedRemoteLookup(getLzChainId(dstNetwork)));
        // print manager
        console.log("manager: ", address(relay._managerAddress()));
        // print gas limit for all method
        console.log(
            "deposit gas: ", relay._flowGasLimitMapping(uint8(OrderlyCrossChainMessage.CrossChainMethod.Deposit))
        );
        console.log(
            "withdraw gas: ", relay._flowGasLimitMapping(uint8(OrderlyCrossChainMessage.CrossChainMethod.Withdraw))
        );
        console.log(
            "withdrawFinish gas: ",
            relay._flowGasLimitMapping(uint8(OrderlyCrossChainMessage.CrossChainMethod.WithdrawFinish))
        );
        console.log("ping gas: ", relay._flowGasLimitMapping(uint8(OrderlyCrossChainMessage.CrossChainMethod.Ping)));
        console.log(
            "pingPong gas: ", relay._flowGasLimitMapping(uint8(OrderlyCrossChainMessage.CrossChainMethod.PingPong))
        );

        vm.stopBroadcast();
    }
}
