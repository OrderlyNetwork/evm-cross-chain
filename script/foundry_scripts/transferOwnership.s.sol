// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TransferOwnership is BaseScript, ConfigHelper {
    using StringUtils for string;

    function run() external {
        string memory network = vm.envString("FS_transferOwnership_network");
        address contractAddress = vm.envAddress("FS_transferOwnership_contract");
        address newOwner = vm.envAddress("FS_transferOwnership_newOwner");

        vmSelectRpcAndBroadcast(network);

        OwnableUpgradeable(contractAddress).transferOwnership(newOwner);

        vm.stopBroadcast();
    }
}
