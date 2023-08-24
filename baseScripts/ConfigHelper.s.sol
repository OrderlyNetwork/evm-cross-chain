// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "./Utils.sol";


struct CCManagerDeployData {
    address manager;
    address owner;
    address proxy;
    string role;
}

struct RelayDeployData {
    address owner;
    address proxy;
    address relay;
}


contract ConfigHelper is Script {
    using StringUtils for string;

    function getConfigFileData(string memory envVar) internal view returns (bytes memory) {
        string memory configFile = vm.envString(envVar);
        string memory fileData = vm.readFile(configFile);
        bytes memory encodedData = vm.parseJson(fileData);
        return encodedData;
    }

    function formKey(string memory key1, string memory key2) internal pure returns (string memory) {
        return key1.formJsonKey().concat(key2.formJsonKey());
    }

    function formKey(string memory key1, string memory key2, string memory key3) internal pure returns (string memory) {
        return key1.formJsonKey().concat(key2.formJsonKey().concat(key3.formJsonKey()));
    }

    function getCCManagerDeployData(string memory env, string memory network) internal returns (CCManagerDeployData memory) {
        string memory deploySavePath = vm.envString("DEPLOY_CCMANAGER_SAVE_FILE");
        string memory deployData = vm.readFile(deploySavePath);
        string memory networkKey = env.formJsonKey().concat(network.formJsonKey());
        bytes memory networkEncodeData = vm.parseJson(deployData, networkKey);
        CCManagerDeployData memory networkManagerData = abi.decode(networkEncodeData, (CCManagerDeployData));
        // close file
        vm.closeFile(deploySavePath);
        return networkManagerData;
    }

    function getRelayDeployData(string memory env, string memory network) internal returns (RelayDeployData memory) {
        string memory deploySavePath = vm.envString("DEPLOY_RELAY_SAVE_FILE");
        string memory deployData = vm.readFile(deploySavePath);
        string memory networkKey = env.formJsonKey().concat(network.formJsonKey());
        bytes memory networkEncodeData = vm.parseJson(deployData, networkKey);
        RelayDeployData memory networkRelayData = abi.decode(networkEncodeData, (RelayDeployData));
        // close file
        vm.closeFile(deploySavePath);
        return networkRelayData;
    }

    function writeToJsonFileByKey(string memory value, string memory path, string memory key1, string memory key2) internal {
        vm.writeJson(value, path, formKey(key1, key2));
    }

    function writeToJsonFileByKey(string memory value, string memory path, string memory key1, string memory key2, string memory key3) internal {
        vm.writeJson(value, path, formKey(key1, key2, key3));
    }
}
