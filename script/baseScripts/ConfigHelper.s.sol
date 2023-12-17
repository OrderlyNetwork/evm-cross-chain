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

struct TokenDecimalConfig {
    uint256 decimals;
    string name;
    bytes32 tokenHash;
}

contract ConfigHelper is Script {
    using StringUtils for string;

    function getConfigFileData(string memory envVar) internal returns (bytes memory) {
        string memory configFile = vm.envString(envVar);
        string memory fileData = vm.readFile(configFile);
        bytes memory encodedData = vm.parseJson(fileData);

        vm.closeFile(configFile);

        return encodedData;
    }

    function formKey(string memory key1, string memory key2) internal pure returns (string memory) {
        return key1.formJsonKey().concat(key2.formJsonKey());
    }

    function formKey(string memory key1, string memory key2, string memory key3)
        internal
        pure
        returns (string memory)
    {
        return key1.formJsonKey().concat(key2.formJsonKey().concat(key3.formJsonKey()));
    }

    function getValueByKey(string memory path, string memory key1, string memory key2, string memory key3)
        internal
        view
        returns (bytes memory)
    {
        string memory fileData = vm.readFile(path);
        bytes memory encodedData = vm.parseJson(fileData, formKey(key1, key2, key3));
        return encodedData;
    }

    function getValueByKey(string memory path, string memory key1, string memory key2)
        internal
        view
        returns (bytes memory)
    {
        string memory fileData = vm.readFile(path);
        bytes memory encodedData = vm.parseJson(fileData, formKey(key1, key2));
        return encodedData;
    }

    function getCCManagerDeployData(string memory env, string memory network)
        internal
        returns (CCManagerDeployData memory)
    {
        string memory deploySavePath = vm.envString("DEPLOY_CCMANAGER_SAVE_FILE");
        string memory deployData = vm.readFile(deploySavePath);
        string memory networkKey = env.formJsonKey().concat(network.formJsonKey());
        bytes memory networkEncodeData = vm.parseJson(deployData, networkKey);
        CCManagerDeployData memory networkManagerData = abi.decode(networkEncodeData, (CCManagerDeployData));
        // close file
        vm.closeFile(deploySavePath);
        return networkManagerData;
    }

    function writeCCManagerDeployData(string memory env, string memory network, string memory key, string memory value)
        internal
    {
        string memory deploySavePath = vm.envString("DEPLOY_CCMANAGER_SAVE_FILE");
        string memory networkKey = env.formJsonKey().concat(network.formJsonKey()).concat(key.formJsonKey());
        vm.writeJson(value, deploySavePath, networkKey);
    }

    function writeCCManagerDeployData(string memory env, string memory network, CCManagerDeployData memory data)
        internal
    {
        string memory deploySaveFile = vm.envString("DEPLOY_CCMANAGER_SAVE_FILE");
        writeToJsonFileByKey(vm.toString(data.proxy), deploySaveFile, env, network, "proxy");
        writeToJsonFileByKey(vm.toString(data.manager), deploySaveFile, env, network, "manager");
        writeToJsonFileByKey(vm.toString(data.owner), deploySaveFile, env, network, "owner");
        writeToJsonFileByKey(data.role, deploySaveFile, env, network, "role");
    }

    function writeCCManagerDeployData(
        string memory env,
        string memory network,
        string memory role,
        address manager,
        address proxy,
        address owner
    ) internal {
        string memory deploySaveFile = vm.envString("DEPLOY_CCMANAGER_SAVE_FILE");
        writeToJsonFileByKey(vm.toString(proxy), deploySaveFile, env, network, "proxy");
        writeToJsonFileByKey(vm.toString(manager), deploySaveFile, env, network, "manager");
        writeToJsonFileByKey(vm.toString(owner), deploySaveFile, env, network, "owner");
        writeToJsonFileByKey(role, deploySaveFile, env, network, "role");
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

    function writeRelayDeployData(string memory env, string memory network, RelayDeployData memory data) internal {
        string memory deploySaveFile = vm.envString("DEPLOY_RELAY_SAVE_FILE");
        writeToJsonFileByKey(vm.toString(data.proxy), deploySaveFile, env, network, "proxy");
        writeToJsonFileByKey(vm.toString(data.relay), deploySaveFile, env, network, "relay");
        writeToJsonFileByKey(vm.toString(data.owner), deploySaveFile, env, network, "owner");
    }

    function writeRelayDeployData(string memory env, string memory network, address relay, address proxy, address owner)
        internal
    {
        string memory deploySaveFile = vm.envString("DEPLOY_RELAY_SAVE_FILE");
        writeToJsonFileByKey(vm.toString(proxy), deploySaveFile, env, network, "proxy");
        writeToJsonFileByKey(vm.toString(relay), deploySaveFile, env, network, "relay");
        writeToJsonFileByKey(vm.toString(owner), deploySaveFile, env, network, "owner");
    }

    function writeRelayDeployData(string memory env, string memory network, string memory key, string memory value)
        internal
    {
        string memory deploySavePath = vm.envString("DEPLOY_RELAY_SAVE_FILE");
        string memory networkKey = env.formJsonKey().concat(network.formJsonKey()).concat(key.formJsonKey());
        vm.writeJson(value, deploySavePath, networkKey);
    }

    function writeToJsonFileByKey(string memory value, string memory path, string memory key1, string memory key2)
        internal
    {
        vm.writeJson(value, path, formKey(key1, key2));
    }

    function writeToJsonFileByKey(
        string memory value,
        string memory path,
        string memory key1,
        string memory key2,
        string memory key3
    ) internal {
        vm.writeJson(value, path, formKey(key1, key2, key3));
    }

    function getTokenDecimals(string memory env, string memory network)
        internal
        view
        returns (TokenDecimalConfig[] memory)
    {
        string memory tokenDecimalsConfigPath = vm.envString("TOKEN_DECIMAL_CONFIG_FILE");
        bytes memory encodedData = getValueByKey(tokenDecimalsConfigPath, env, network);
        TokenDecimalConfig[] memory configs = abi.decode(encodedData, (TokenDecimalConfig[]));
        return configs;
    }

    function getLedgerAddress(string memory env, string memory network) internal view returns (address) {
        string memory projectRelatedFile = vm.envString("DEPLOY_PROJECT_RELATED_FILE");
        bytes memory ledgerData = getValueByKey(projectRelatedFile, env, network, "ledger");
        return abi.decode(ledgerData, (address));
    }

    function getVaultAddress(string memory env, string memory network) internal view returns (address) {
        string memory projectRelatedFile = vm.envString("DEPLOY_PROJECT_RELATED_FILE");
        bytes memory vaultData = getValueByKey(projectRelatedFile, env, network, "vault");
        return abi.decode(vaultData, (address));
    }

    function getOperatorAddress(string memory env, string memory network) internal view returns (address) {
        string memory projectRelatedFile = vm.envString("DEPLOY_PROJECT_RELATED_FILE");
        bytes memory data = getValueByKey(projectRelatedFile, env, network, "operator-manager");
        return abi.decode(data, (address));
    }
}
