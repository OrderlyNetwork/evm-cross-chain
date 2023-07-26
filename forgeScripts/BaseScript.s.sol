// SPDX-License-Identifier: Apache-2.0
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
}
