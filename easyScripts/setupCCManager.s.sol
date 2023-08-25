// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../baseScripts/BaseScript.s.sol";
import "../baseScripts/ConfigHelper.s.sol";
import "../contracts/LedgerCrossChainManagerUpgradeable.sol";
import "../contracts/CrossChainManagerProxy.sol";
import "../contracts/VaultCrossChainManagerUpgradeable.sol";

contract SetupCCManager is BaseScript, ConfigHelper {
    using StringUtils for string;

    // variable order must be alphabetical
    struct SetupCCManagerConfig {
        string env;
        string ledgerNetwork;
        string vaultNetwork;
    }

    function run() external {
        bytes memory encodedData = getConfigFileData("DEPLOY_CCMANAGER_CONFIG_FILE");
        SetupCCManagerConfig memory config = abi.decode(encodedData, (SetupCCManagerConfig));
        console.log("vaultNetwork: ", config.vaultNetwork);
        console.log("ledgerNetwork: ", config.ledgerNetwork);
        console.log("env: ", config.env);

        CCManagerDeployData memory vaultDeployData = getCCManagerDeployData(config.env, config.vaultNetwork);
        CCManagerDeployData memory ledgerDeployData = getCCManagerDeployData(config.env, config.ledgerNetwork);

        RelayDeployData memory vaultRelayData = getRelayDeployData(config.env, config.vaultNetwork);
        RelayDeployData memory ledgerRelayData = getRelayDeployData(config.env, config.ledgerNetwork);

        // logging everything in function call
        console.log("vaultDeployData.proxy: ", vaultDeployData.proxy);
        console.log("ledgerDeployData.proxy: ", ledgerDeployData.proxy);
        console.log("vaultRelayData.proxy: ", vaultRelayData.proxy);
        console.log("ledgerRelayData.proxy: ", ledgerRelayData.proxy);

        setupLedger(config.ledgerNetwork, config.env, vaultDeployData.proxy, vaultRelayData.proxy);

        setupVault(
            config.vaultNetwork,
            config.ledgerNetwork,
            config.env,
            vaultDeployData.proxy,
            ledgerDeployData.proxy,
            vaultRelayData.proxy
        );
    }

    function setupLedger(string memory network, string memory env, address managerAddress, address relayAddress)
        internal
    {
        console.log("network: ", network);

        uint256 chainId = getChainId(network);

        string memory projectRelatedFile = vm.envString("DEPLOY_PROJECT_RELATED_FILE");

        bytes memory ledgerEncodedData = getValueByKey(projectRelatedFile, env, network, "ledger");
        bytes memory operatorEncodedData = getValueByKey(projectRelatedFile, env, network, "operator-manager");
        address ledgerAddr = abi.decode(ledgerEncodedData, (address));
        address operatorAddr = abi.decode(operatorEncodedData, (address));

        vmSelectRpcAndBroadcast(network);

        LedgerCrossChainManagerUpgradeable ledger = LedgerCrossChainManagerUpgradeable(payable(managerAddress));

        ledger.setChainId(chainId);
        ledger.setLedger(ledgerAddr);
        ledger.setOperatorManager(operatorAddr);
        ledger.setCrossChainRelay(relayAddress);

        ledger.setTokenDecimal(0xd6aca1be9729c13d677335161321649cccae6a591554772516700f986f942eaa, 4460, 6);
        ledger.setTokenDecimal(0xd6aca1be9729c13d677335161321649cccae6a591554772516700f986f942eaa, 421613, 6);

        vm.stopBroadcast();
    }

    function setupVault(
        string memory network,
        string memory ledgerNetwork,
        string memory env,
        address managerAddress,
        address ledgerManagerAddress,
        address relayAddress
    ) internal {
        console.log("network: ", network);

        uint256 chainId = getChainId(network);
        uint256 ledgerChainId = getChainId(ledgerNetwork);

        string memory projectRelatedFile = vm.envString("DEPLOY_PROJECT_RELATED_FILE");

        bytes memory vaultEncodedData = getValueByKey(projectRelatedFile, env, network, "vault");
        address vaultAddr = abi.decode(vaultEncodedData, (address));

        vmSelectRpcAndBroadcast(network);

        VaultCrossChainManagerUpgradeable vault = VaultCrossChainManagerUpgradeable(payable(managerAddress));

        vault.setChainId(chainId);
        vault.setVault(vaultAddr);
        vault.setCrossChainRelay(relayAddress);
        vault.setLedgerCrossChainManager(ledgerChainId, ledgerManagerAddress);

        vm.stopBroadcast();
    }
}
