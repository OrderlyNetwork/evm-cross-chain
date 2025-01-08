// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "./Utils.sol";

contract BaseScript is Script {
    using StringUtils for string;

    function vmSelectRpcAndBroadcast(string memory env, string memory network) internal {
        string memory rpcUrl = getRpcUrl(network);
        uint256 pk = getPrivateKey(env);
        vm.createSelectFork(rpcUrl); 
        vm.startBroadcast(pk);
    }

    function vmSelectRpc(string memory network) internal {
        string memory rpcUrl = getRpcUrl(network);
        vm.createSelectFork(rpcUrl); 
    }

    function getRpcUrl(string memory network) internal view returns (string memory) {
        return vm.envString(network.toUpperCase().concat("_RPC_URL"));
    }

    function getPrivateKey(string memory env) internal view returns (uint256) {
        return vm.envUint(env.toUpperCase().concat("_PK"));
    }

    function getLzEndpoint(string memory network) internal view returns (address) {
        return vm.envAddress(network.toUpperCase().concat("_ENDPOINT"));
    }

    function getChainId(string memory network) internal view returns (uint256) {
        return vm.envUint(network.toUpperCase().concat("_CHAIN_ID"));
    }

    function getLzChainId(string memory network) internal view returns (uint16) {
        return uint16(vm.envUint(network.toUpperCase().concat("_LZ_CHAIN_ID")));
    }

}
