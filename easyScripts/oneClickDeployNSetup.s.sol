// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "../contracts/CrossChainRelayProxy.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/LedgerCrossChainManagerUpgradeable.sol";
import "../contracts/CrossChainManagerProxy.sol";
import "../contracts/VaultCrossChainManagerUpgradeable.sol";

contract OneClickDeploy is BaseScript, ConfigHelper {
    using StringUtils for string;

    // variable order must be alphabetical
    struct DeployCCManagerConfig {
        string env;
        string ledgerNetwork;
        string vaultNetwork;
    }

    function run() external {
        bytes memory encodedData = getConfigFileData("ONE_CLICK_DEPLOY_RELAY_CCMANAGER_CONFIG_FILE");
        DeployCCManagerConfig memory config = abi.decode(encodedData, (DeployCCManagerConfig));
        console.log("vaultNetwork: ", config.vaultNetwork);
        console.log("ledgerNetwork: ", config.ledgerNetwork);
        console.log("env: ", config.env);

        console.log("deploying ledger");
        // deploy ledger cc manager and relay
        CCManagerDeployData memory ledgerDeployData = deployLedger(config.ledgerNetwork);

        console.log("deploying relay");
        RelayDeployData memory ledgerRelayData = deployRelay(config.ledgerNetwork);
        // deploy vault cc manager and relay
        console.log("deploying vault");
        CCManagerDeployData memory vaultDeployData = deployVault(config.vaultNetwork);

        console.log("deploying relay");
        RelayDeployData memory vaultRelayData = deployRelay(config.vaultNetwork);
        // setup ledger cc manager and relay
        console.log("setup ledger");
        setupLedger(
            config.ledgerNetwork, config.vaultNetwork, config.env, ledgerDeployData.proxy, ledgerRelayData.proxy
        );
        console.log("setup relay");
        setupRelay(
            config.ledgerNetwork,
            config.vaultNetwork,
            ledgerRelayData.proxy,
            vaultRelayData.proxy,
            config.env,
            ledgerDeployData.proxy
        );

        // setup vault cc manager and relay
        console.log("setup vault");
        setupVault(
            config.vaultNetwork,
            config.ledgerNetwork,
            config.env,
            vaultDeployData.proxy,
            ledgerDeployData.proxy,
            vaultRelayData.proxy
        );
        console.log("setup relay");
        setupRelay(
            config.vaultNetwork,
            config.ledgerNetwork,
            vaultRelayData.proxy,
            ledgerRelayData.proxy,
            config.env,
            vaultDeployData.proxy
        );

        // write ledger cc manager deploy data
        writeCCManagerDeployData(config.env, config.ledgerNetwork, ledgerDeployData);

        // write vault cc manager deploy data
        writeCCManagerDeployData(config.env, config.vaultNetwork, vaultDeployData);

        // write relay deployment data
        writeRelayDeployData(config.env, config.ledgerNetwork, ledgerRelayData);
        writeRelayDeployData(config.env, config.vaultNetwork, vaultRelayData);
    }

    function setupLedger(
        string memory network,
        string memory vaultNetwork,
        string memory env,
        address managerAddress,
        address relayAddress
    ) internal {
        console.log("network: ", network);

        uint256 chainId = getChainId(network);

        string memory projectRelatedFile = vm.envString("DEPLOY_PROJECT_RELATED_FILE");

        bytes memory ledgerEncodedData = getValueByKey(projectRelatedFile, env, network, "ledger");
        bytes memory operatorEncodedData = getValueByKey(projectRelatedFile, env, network, "operator-manager");
        address ledgerAddr = abi.decode(ledgerEncodedData, (address));
        address operatorAddr = abi.decode(operatorEncodedData, (address));

        console.log("cc manager setup start");
        vmSelectRpcAndBroadcast(network);

        LedgerCrossChainManagerUpgradeable ledger = LedgerCrossChainManagerUpgradeable(payable(managerAddress));

        ledger.setChainId(chainId);
        ledger.setLedger(ledgerAddr);
        ledger.setOperatorManager(operatorAddr);
        ledger.setCrossChainRelay(relayAddress);

        TokenDecimalConfig[] memory ledgerNetworkTokenConfigs = getTokenDecimals(env, network);
        for (uint256 i = 0; i < ledgerNetworkTokenConfigs.length; i++) {
            ledger.setTokenDecimal(
                ledgerNetworkTokenConfigs[i].tokenHash,
                getChainId(network),
                uint128(ledgerNetworkTokenConfigs[i].decimals)
            );
        }

        TokenDecimalConfig[] memory vaultNetworkTokenConfigs = getTokenDecimals(env, vaultNetwork);
        for (uint256 i = 0; i < vaultNetworkTokenConfigs.length; i++) {
            ledger.setTokenDecimal(
                vaultNetworkTokenConfigs[i].tokenHash,
                getChainId(vaultNetwork),
                uint128(vaultNetworkTokenConfigs[i].decimals)
            );
        }

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

    function setupRelay(
        string memory srcNetwork,
        string memory dstNetwork,
        address srcRelayProxyAddress,
        address dstRelayProxyAddress,
        string memory,
        address managerAddress
    ) internal {
        CrossChainRelayUpgradeable relay = CrossChainRelayUpgradeable(payable(srcRelayProxyAddress));

        vmSelectRpcAndBroadcast(srcNetwork);

        // 1. call and send 2 ether to relay handle return
        (bool success,) = srcRelayProxyAddress.call{value: 1 ether}("");
        require(success, "transfer failed");

        // 2. add chain Id mapping
        relay.addChainIdMapping(getChainId(srcNetwork), getLzChainId(srcNetwork));
        relay.addChainIdMapping(getChainId(dstNetwork), getLzChainId(dstNetwork));
        // 3. set src chain Id
        relay.setSrcChainId(getChainId(srcNetwork));
        // 4. set manager address
        relay.setManagerAddress(managerAddress);
        // 5. set trusted remote
        bytes memory remoteAndLocal = abi.encodePacked(dstRelayProxyAddress, dstRelayProxyAddress);
        relay.setTrustedRemote(getLzChainId(dstNetwork), remoteAndLocal);

        vm.stopBroadcast();
    }

    function deployRelay(string memory network) internal returns (RelayDeployData memory) {
        console.log("network: ", network);

        uint256 pk = getPrivateKey(network);

        vmSelectRpcAndBroadcast(network);

        CrossChainRelayUpgradeable relay = new CrossChainRelayUpgradeable();
        console.log("deployed relay address: ", address(relay));
        CrossChainRelayProxy relayProxy = new CrossChainRelayProxy(address(relay), bytes(""));
        console.log("deployed relay proxy address: ", address(relayProxy));
        CrossChainRelayUpgradeable relayUpgradeable = CrossChainRelayUpgradeable(payable(address(relayProxy)));
        relayUpgradeable.initialize(getLzEndpoint(network));

        vm.stopBroadcast();

        // construct Manager Deploy Data
        RelayDeployData memory relayDeployData = RelayDeployData(vm.addr(pk), address(relayProxy), address(relay));

        return relayDeployData;
    }

    function deployLedger(string memory network) internal returns (CCManagerDeployData memory) {
        console.log("network: ", network);

        uint256 pk = getPrivateKey(network);

        vmSelectRpcAndBroadcast(network);

        LedgerCrossChainManagerUpgradeable ledger = new LedgerCrossChainManagerUpgradeable();
        console.log("deployed ledger address: ", address(ledger));
        CrossChainManagerProxy ledgerProxy = new CrossChainManagerProxy(address(ledger), bytes(""));
        console.log("deployed ledger proxy address: ", address(ledgerProxy));
        LedgerCrossChainManagerUpgradeable ledgerUpgradeable =
            LedgerCrossChainManagerUpgradeable(payable(address(ledgerProxy)));
        ledgerUpgradeable.initialize();

        vm.stopBroadcast();

        // construct Manager Deploy Data
        CCManagerDeployData memory ledgerDeployData =
            CCManagerDeployData(address(ledger), vm.addr(pk), address(ledgerProxy), "ledger");

        return ledgerDeployData;
    }

    function deployVault(string memory network) internal returns (CCManagerDeployData memory) {
        console.log("network: ", network);

        uint256 pk = getPrivateKey(network);

        vmSelectRpcAndBroadcast(network);

        VaultCrossChainManagerUpgradeable vault = new VaultCrossChainManagerUpgradeable();
        console.log("deployed vault address: ", address(vault));
        CrossChainManagerProxy vaultProxy = new CrossChainManagerProxy(address(vault), bytes(""));
        console.log("deployed vault proxy address: ", address(vaultProxy));
        VaultCrossChainManagerUpgradeable vaultUpgradeable =
            VaultCrossChainManagerUpgradeable(payable(address(vaultProxy)));
        vaultUpgradeable.initialize();

        vm.stopBroadcast();

        // construct Manager Deploy Data
        CCManagerDeployData memory vaultDeployData =
            CCManagerDeployData(address(vault), vm.addr(pk), address(vaultProxy), "vault");

        return vaultDeployData;
    }
}
