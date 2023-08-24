// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "./Utils.sol";

contract BaseScript is Script {
    using StringUtils for string;

    function vmSelectRpcAndBroadcast(string memory network) internal {
        string memory rpcUrl = getRpcUrl(network);
        uint256 pk = getPrivateKey(network);
        vm.createSelectFork(rpcUrl); 
        vm.startBroadcast(pk);
    }

    function getRpcUrl(string memory network) internal view returns (string memory) {
        return vm.envString(string("RPC_URL_").concat(network.toUpperCase()));
    }

    function getPrivateKey(string memory network) internal view returns (uint256) {
        return vm.envUint(network.toUpperCase().concat("_PRIVATE_KEY"));
    }

    function getLzEndpoint(string memory network) internal view returns (address) {
        return vm.envAddress(network.toUpperCase().concat("_ENDPOINT"));
    }

    function getRelayProxyAddress(string memory network) internal view returns (address) {
        return vm.envAddress(network.toUpperCase().concat("_RELAY_PROXY"));
    }

    function getManagerProxyAddress(string memory network) internal view returns (address) {
        return vm.envAddress(network.toUpperCase().concat("_MANAGER_PROXY"));
    }

    function getChainId(string memory network) internal view returns (uint256) {
        return vm.envUint(network.toUpperCase().concat("_CHAIN_ID"));
    }

    function getLzChainId(string memory network) internal view returns (uint16) {
        return uint16(vm.envUint(network.toUpperCase().concat("_LZ_CHAIN_ID")));
}

    function getOperatorManagerAddress(string memory network) internal view returns (address) {
        return vm.envAddress(network.toUpperCase().concat("_OPERATOR_MANAGER"));
    }

    function getVaultAddress(string memory network) internal view returns (address) {
        return vm.envAddress(network.toUpperCase().concat("_VAULT"));
    }

    function getLedgerAddress(string memory network) internal view returns (address) {
        return vm.envAddress(network.toUpperCase().concat("_LEDGER"));
    }
}
