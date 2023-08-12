// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "./Utils.sol";

contract BaseScript is Script {
    using StringCompare for string;

    function getPrivateKey(string memory network) internal view returns (uint256) {
        if (network.compare("fuji")) {
            return vm.envUint("FUJI_PRIVATE_KEY");
        } else if (network.compare("mumbai")) {
            return vm.envUint("MUMBAI_PRIVATE_KEY");
        } else if (network.compare("orderly")) {
            return vm.envUint("ORDERLY_PRIVATE_KEY");
        } else {
            revert("Invalid network");
        }
    }

    function getLzEndpoint(string memory network) internal view returns (address) {
        if (network.compare("fuji")) {
            return vm.envAddress("FUJI_ENDPOINT");
        } else if (network.compare("mumbai")) {
            return vm.envAddress("MUMBAI_ENDPOINT");
        } else if (network.compare("orderly")) {
            return vm.envAddress("ORDERLY_ENDPOINT");
        } else {
            revert("Invalid network");
        }
    }

    function getRelayProxyAddress(string memory network) internal view returns (address) {
        if (network.compare("fuji")) {
            return vm.envAddress("FUJI_RELAY_PROXY");
        } else if (network.compare("mumbai")) {
            return vm.envAddress("MUMBAI_RELAY_PROXY");
        } else if (network.compare("orderly")) {
            return vm.envAddress("ORDERLY_RELAY_PROXY");
        } else {
            revert("Invalid network");
        }
    }

    function getManagerProxyAddress(string memory network) internal view returns (address) {
        if (network.compare("fuji")) {
            return vm.envAddress("FUJI_MANAGER_PROXY");
        } else if (network.compare("mumbai")) {
            return vm.envAddress("MUMBAI_MANAGER_PROXY");
        } else if (network.compare("orderly")) {
            return vm.envAddress("ORDERLY_MANAGER_PROXY");
        } else {
            revert("Invalid network");
        }
    }

    function getChainId(string memory network) internal view returns (uint256) {
        if (network.compare("fuji")) {
            return vm.envUint("FUJI_CHAIN_ID");
        } else if (network.compare("mumbai")) {
            return vm.envUint("MUMBAI_CHAIN_ID");
        } else if (network.compare("orderly")) {
            return vm.envUint("ORDERLY_CHAIN_ID");
        } else {
            revert("Invalid network");
        }
    }

    function getOperatorManagerAddress(string memory network) internal view returns (address) {
        if (network.compare("fuji")) {
            return vm.envAddress("FUJI_OPERATOR_MANAGER");
        } else if (network.compare("mumbai")) {
            return vm.envAddress("MUMBAI_OPERATOR_MANAGER");
        } else if (network.compare("orderly")) {
            return vm.envAddress("ORDERLY_OPERATOR_MANAGER");
        } else {
            revert("Invalid network");
        }
    }

    function getVaultAddress(string memory network) internal view returns (address) {
        if (network.compare("fuji")) {
            return vm.envAddress("FUJI_VAULT");
        } else if (network.compare("mumbai")) {
            return vm.envAddress("MUMBAI_VAULT");
        } else if (network.compare("orderly")) {
            return vm.envAddress("ORDERLY_VAULT");
        } else {
            revert("Invalid network");
        }
    }

    function getLedgerAddress(string memory network) internal view returns (address) {
        if (network.compare("fuji")) {
            return vm.envAddress("FUJI_LEDGER");
        } else if (network.compare("mumbai")) {
            return vm.envAddress("MUMBAI_LEDGER");
        } else if (network.compare("orderly")) {
            return vm.envAddress("ORDERLY_LEDGER");
        } else {
            revert("Invalid network");
        }
    }
}
