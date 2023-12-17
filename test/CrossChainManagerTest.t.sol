pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "./CrossChainManagerSetup.t.sol";
import "../contracts/interface/IOrderlyCrossChain.sol";
import "evm-cross-chain/script/baseScripts/ConfigHelper.s.sol";
import "evm-cross-chain/script/baseScripts/BaseScript.s.sol";
import "../contracts/test/WrongImplementation.sol";

contract CrossChainManagerTest is Test, CrossChainManagerSetup, ConfigHelper, BaseScript {
    event MessageSent(OrderlyCrossChainMessage.MessageV1 message, bytes payload);
    event MessageReceived(OrderlyCrossChainMessage.MessageV1 message, bytes payload);

    CrossChainManagerFactory factory;

    function setUp() public {
        deployCrossChainManager();
        setupCrossChainManager();
        factory = new CrossChainManagerFactory();
    }

    function test_sendTestWithdrawMessage() public {
        (bool suc1,) = payable(_dstRelayProxy).call{value: 1 ether}("");
        (bool suc2,) = payable(_srcRelayProxy).call{value: 1 ether}("");
        require(suc1 && suc2, "failed to send ether to relays");

        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Withdraw),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.EventTypesWithdrawData),
            srcCrossChainManager: address(_ledgerManagerProxy),
            dstCrossChainManager: address(_vaultManagerProxy),
            srcChainId: _ledgerChainId,
            dstChainId: _vaultChainId
        });

        vm.expectEmit(true, false, false, false);
        emit MessageReceived(message, bytes(""));

        vm.expectEmit(true, false, false, false);
        emit MessageReceived(message, bytes(""));

        vm.expectEmit(true, false, false, false);
        emit MessageSent(message, bytes(""));

        vm.expectEmit(true, false, false, false);
        emit MessageSent(message, bytes(""));

        _ledgerManagerProxy.sendTestWithdraw(_vaultChainId);
    }

    function testFail_vaultUpgradeTo() public {
        address newImplementation = 0x1234567890123456789012345678901234567890;
        _vaultManagerProxy.upgradeTo(newImplementation);
    }

    function testFail_ledgerUpgradeTo() public {
        address newImplementation = 0x1234567890123456789012345678901234567890;
        _ledgerManagerProxy.upgradeTo(newImplementation);
    }

    function test_upgradeTo() public {
        _vaultManagerProxy.upgradeTo(address(new VaultCrossChainManagerUpgradeable()));
        _ledgerManagerProxy.upgradeTo(address(new LedgerCrossChainManagerUpgradeable()));
    }

    function testFuzz_tokenDecimal(
        bytes32 tokenHash,
        uint256 chainId1,
        uint256 chainId2,
        uint128 decimal1,
        uint128 decimal2,
        uint128 tokenAmount
    ) public {
        vm.assume(decimal1 < 24 && decimal2 < 24);
        vm.assume(decimal1 > decimal2);
        vm.assume(decimal1 - decimal2 <= 12);
        vm.assume(tokenAmount < 340_000_000_000_000_000_000_000_000);
        vm.assume(chainId1 != chainId2);
        _ledgerManagerProxy.setTokenDecimal(tokenHash, chainId1, decimal1);
        _ledgerManagerProxy.setTokenDecimal(tokenHash, chainId2, decimal2);

        _ledgerManagerProxy.convertDecimal(tokenAmount, tokenHash, chainId1, chainId2);
        _ledgerManagerProxy.convertDecimal(tokenAmount, tokenHash, chainId2, chainId1);

        // assertEq(convertedAmount, tokenAmount * (10 ** decimal2) / (10 ** decimal1));

        // _ledgerManagerProxy.setTokenDecimal(tokenHash, chainId1, decimal2);
        // _ledgerManagerProxy.setTokenDecimal(tokenHash, chainId2, decimal1);

        // convertedAmount = _ledgerManagerProxy.convertDecimal(tokenAmount, tokenHash, chainId1, chainId2);

        // assertEq(convertedAmount, tokenAmount * (10 ** decimal1) / (10 ** decimal2));
    }

    function test_notOwnerSetTokenDecimalFail() public {
        LedgerCrossChainManagerUpgradeable ledgerManagerProxy =
            LedgerCrossChainManagerUpgradeable(address(factory.newLedgerCrossChainManager()));

        vm.expectRevert("Ownable: caller is not the owner");
        ledgerManagerProxy.setTokenDecimal(bytes32(0), 0, 0);
    }

    function upgradeCompatible(string memory env, string memory network1, string memory network2) public {
        CCManagerDeployData memory data1 = getCCManagerDeployData(env, network1);
        assertEq(data1.role, "ledger");
        CCManagerDeployData memory data2 = getCCManagerDeployData(env, network2);
        assertEq(data2.role, "vault");
        LedgerCrossChainManagerUpgradeable ledgerManagerProxy = LedgerCrossChainManagerUpgradeable(data1.proxy);
        VaultCrossChainManagerUpgradeable vaultManagerProxy = VaultCrossChainManagerUpgradeable(data2.proxy);

        string memory url1 = getRpcUrl(network1);
        uint256 pk1 = getPrivateKey(network1);
        vm.createSelectFork(url1);
        vm.startBroadcast(pk1);
        ledgerManagerProxy.upgradeTo(address(new LedgerCrossChainManagerUpgradeable()));
        ledgerManagerProxy.upgradeTo(address(new LedgerCrossChainManagerUpgradeable()));
        vm.stopBroadcast();

        string memory url2 = getRpcUrl(network2);
        uint256 pk2 = getPrivateKey(network2);
        vm.createSelectFork(url2);
        vm.startBroadcast(pk2);
        vaultManagerProxy.upgradeTo(address(new VaultCrossChainManagerUpgradeable()));
        vaultManagerProxy.upgradeTo(address(new VaultCrossChainManagerUpgradeable()));
        vm.stopBroadcast();
    }

    function test_upgradeCompatible() public {
        string memory env = "dev";
        string memory network1 = "orderlyop";
        string memory network2 = "arbitrumgoerli";
        upgradeCompatible(env, network1, network2);
        env = "staging";
        upgradeCompatible(env, network1, network2);
        env = "qa";
        upgradeCompatible(env, network1, network2);
    }

    function upgradeIncompatible(string memory env, string memory network1, string memory network2) public {
        CCManagerDeployData memory data1 = getCCManagerDeployData(env, network1);
        assertEq(data1.role, "ledger");
        CCManagerDeployData memory data2 = getCCManagerDeployData(env, network2);
        assertEq(data2.role, "vault");
        LedgerCrossChainManagerUpgradeable ledgerManagerProxy = LedgerCrossChainManagerUpgradeable(data1.proxy);
        VaultCrossChainManagerUpgradeable vaultManagerProxy = VaultCrossChainManagerUpgradeable(data2.proxy);

        string memory url1 = getRpcUrl(network1);
        uint256 pk1 = getPrivateKey(network1);
        vm.createSelectFork(url1);
        vm.startBroadcast(pk1);
        ledgerManagerProxy.upgradeTo(address(new WrongImplementation()));
        address newImplementation1 = address(new LedgerCrossChainManagerUpgradeable());
        vm.expectRevert();
        ledgerManagerProxy.upgradeTo(newImplementation1);
        vm.stopBroadcast();

        string memory url2 = getRpcUrl(network2);
        uint256 pk2 = getPrivateKey(network2);
        vm.createSelectFork(url2);
        vm.startBroadcast(pk2);
        vaultManagerProxy.upgradeTo(address(new WrongImplementation()));
        address newImplementation2 = address(new VaultCrossChainManagerUpgradeable());
        vm.expectRevert();
        vaultManagerProxy.upgradeTo(newImplementation2);
        vm.stopBroadcast();
    }

    function test_upgradeIncompatible() public {
        string memory env = "dev";
        string memory network1 = "orderlyop";
        string memory network2 = "arbitrumgoerli";
        upgradeIncompatible(env, network1, network2);
        env = "staging";
        upgradeIncompatible(env, network1, network2);
        env = "qa";
        upgradeIncompatible(env, network1, network2);
    }

    function test_transferOwnership() public {
        address vaultManagerProxy = factory.newVaultCrossChainManager();
        address ledgerManagerProxy = factory.newLedgerCrossChainManager();

        address newLedgerManager = address(new LedgerCrossChainManagerUpgradeable());
        // upgrade to
        vm.expectRevert();
        LedgerCrossChainManagerUpgradeable(ledgerManagerProxy).upgradeTo(newLedgerManager);

        // transfer ownership
        factory.transferOwner(ledgerManagerProxy, address(this));
        // upgrade to
        LedgerCrossChainManagerUpgradeable(ledgerManagerProxy).upgradeTo(
            address(new LedgerCrossChainManagerUpgradeable())
        );

        // now test vault manager

        address newVaultManager = address(new VaultCrossChainManagerUpgradeable());
        // upgrade to
        vm.expectRevert();
        VaultCrossChainManagerUpgradeable(vaultManagerProxy).upgradeTo(newVaultManager);

        // transfer ownership
        factory.transferOwner(vaultManagerProxy, address(this));
        // upgrade to
        VaultCrossChainManagerUpgradeable(vaultManagerProxy).upgradeTo(address(new VaultCrossChainManagerUpgradeable()));
    }
}
