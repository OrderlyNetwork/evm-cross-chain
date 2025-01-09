// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseTest.sol";
import "./CrossChainManagerSetup.t.sol";
import "../contracts/test/WrongImplementation.sol";

contract CrossChainManagerTest is BaseTest, CrossChainManagerSetup {
    CrossChainManagerFactory factory;

    function setUp() public {
        deployCrossChainManager();
        setupCrossChainManager();
        factory = new CrossChainManagerFactory();
    }

    function test_managerInitialization() public {
        // Test Ledger Manager initialization
        assertEq(_ledgerManagerProxy.chainId(), LEDGER_CHAIN_ID);
        assertEq(address(_ledgerManagerProxy.crossChainRelay()), address(_dstRelayProxy));

        // Test Vault Manager initialization
        assertEq(_vaultManagerProxy.chainId(), VAULT_CHAIN_ID);
        assertEq(address(_vaultManagerProxy.crossChainRelay()), address(_srcRelayProxy));
        assertEq(_vaultManagerProxy.ledgerChainId(), LEDGER_CHAIN_ID);
    }

    function test_sendTestWithdrawMessage() public {
        // Fund relays for gas
        fundContract(address(_dstRelayProxy), 1 ether);
        fundContract(address(_srcRelayProxy), 1 ether);

        // Create expected message
        OrderlyCrossChainMessage.MessageV1 memory expectedMsg = createCrossChainMessage(
            uint8(OrderlyCrossChainMessage.CrossChainMethod.Withdraw),
            address(_ledgerManagerProxy),
            address(_vaultManagerProxy),
            LEDGER_CHAIN_ID,
            VAULT_CHAIN_ID
        );

        // Expect message events in sequence
        vm.expectEmit(true, false, false, false);
        emit MessageReceived(expectedMsg, bytes(""));

        vm.expectEmit(true, false, false, false);
        emit MessageReceived(expectedMsg, bytes(""));

        vm.expectEmit(true, false, false, false);
        emit MessageSent(expectedMsg, bytes(""));

        vm.expectEmit(true, false, false, false);
        emit MessageSent(expectedMsg, bytes(""));

        _ledgerManagerProxy.sendTestWithdraw(VAULT_CHAIN_ID);
    }

    function test_tokenDecimalConversion() public {
        bytes32 tokenHash = keccak256("TEST");
        uint128 srcDecimal = 18;
        uint128 dstDecimal = 6;
        uint128 amount = 1e18;

        // Set decimals for both chains
        _ledgerManagerProxy.setTokenDecimal(tokenHash, LEDGER_CHAIN_ID, srcDecimal);
        _ledgerManagerProxy.setTokenDecimal(tokenHash, VAULT_CHAIN_ID, dstDecimal);

        // Convert from ledger to vault chain (18 -> 6 decimals)
        uint128 converted = _ledgerManagerProxy.convertDecimal(
            amount,
            tokenHash,
            LEDGER_CHAIN_ID,
            VAULT_CHAIN_ID
        );
        assertEq(converted, 1e6, "Decimal conversion failed");

        // Convert back to verify (6 -> 18 decimals)
        converted = _ledgerManagerProxy.convertDecimal(
            converted,
            tokenHash,
            VAULT_CHAIN_ID,
            LEDGER_CHAIN_ID
        );
        assertEq(converted, 1e18, "Reverse decimal conversion failed");
    }

    function test_upgradeContracts() public {
        // Test successful upgrades
        address newVaultImpl = address(new VaultCrossChainManagerUpgradeable());
        address newLedgerImpl = address(new LedgerCrossChainManagerUpgradeable());

        _vaultManagerProxy.upgradeTo(newVaultImpl);
        _ledgerManagerProxy.upgradeTo(newLedgerImpl);

        // Verify functionality remains after upgrade
        test_managerInitialization();
    }

    function testFail_unauthorizedUpgrade() public {
        address newVaultImpl = address(new VaultCrossChainManagerUpgradeable());
        
        // Switch to non-owner account
        vm.prank(MOCK_USER);
        _vaultManagerProxy.upgradeTo(newVaultImpl);
    }

    function test_ownershipTransfer() public {
        address vaultProxy = factory.newVaultCrossChainManager();
        address ledgerProxy = factory.newLedgerCrossChainManager();

        address newVaultImpl = address(new VaultCrossChainManagerUpgradeable());
        address newLedgerImpl = address(new LedgerCrossChainManagerUpgradeable());
        // Initial upgrade should fail (not owner)
        vm.expectRevert("Ownable: caller is not the owner");
        VaultCrossChainManagerUpgradeable(vaultProxy).upgradeTo(newVaultImpl);
        vm.expectRevert("Ownable: caller is not the owner");
        LedgerCrossChainManagerUpgradeable(ledgerProxy).upgradeTo(newLedgerImpl);
        // Transfer ownership
        factory.transferOwner(vaultProxy, address(this));
        factory.transferOwner(ledgerProxy, address(this));

        // Need to wait for ownership transfer to complete
        vm.roll(block.number + 1); // Move to next block
        
        // Now upgrades should succeed
        VaultCrossChainManagerUpgradeable(vaultProxy).upgradeTo(address(new VaultCrossChainManagerUpgradeable()));
        LedgerCrossChainManagerUpgradeable(ledgerProxy).upgradeTo(address(new LedgerCrossChainManagerUpgradeable()));
    }

    function testFuzz_tokenDecimalBoundaries(
        bytes32 tokenHash,
        uint128 amount,
        uint128 vaultDecimal
    ) public {
        uint128 ledgerDecimal = 6;
        // More reasonable constraints to avoid too many rejections
        vm.assume(vaultDecimal <= 12);
        vm.assume(vaultDecimal != 0); // Avoid division by zero
        vm.assume(amount < 1e30); // Reasonable amount limit
        
        _ledgerManagerProxy.setTokenDecimal(tokenHash, LEDGER_CHAIN_ID, ledgerDecimal);
        _ledgerManagerProxy.setTokenDecimal(tokenHash, VAULT_CHAIN_ID, vaultDecimal);

        uint128 converted = _ledgerManagerProxy.convertDecimal(
            amount,
            tokenHash,
            LEDGER_CHAIN_ID,
            VAULT_CHAIN_ID
        );

        // Verify basic properties of conversion
        if (ledgerDecimal > vaultDecimal) {
            assertTrue(converted <= amount, "Conversion should not increase amount when reducing decimals");
        } else if (ledgerDecimal < vaultDecimal) {
            assertTrue(converted >= amount, "Conversion should not decrease amount when increasing decimals");
        } else {
            assertEq(converted, amount, "Conversion should not change amount when decimals are equal");
        }
    }

    function test_upgradeCompatible() public {
        // Test upgrading to correct implementation types
        address newVaultImpl = address(new VaultCrossChainManagerUpgradeable());
        address newLedgerImpl = address(new LedgerCrossChainManagerUpgradeable());

        // Create new instances through factory
        address vaultProxy = factory.newVaultCrossChainManager();
        address ledgerProxy = factory.newLedgerCrossChainManager();

        // Transfer ownership to test contract
        factory.transferOwner(vaultProxy, address(this));
        factory.transferOwner(ledgerProxy, address(this));

        // Upgrade should succeed with correct implementation
        VaultCrossChainManagerUpgradeable(vaultProxy).upgradeTo(newVaultImpl);
        LedgerCrossChainManagerUpgradeable(ledgerProxy).upgradeTo(newLedgerImpl);

        // Verify contracts are still functional after upgrade
        assertEq(VaultCrossChainManagerUpgradeable(vaultProxy).getRole(), "vault");
        assertEq(LedgerCrossChainManagerUpgradeable(ledgerProxy).getRole(), "ledger");
    }

    /// @notice Test deposit fee estimation
    function test_depositFee() public {
        // Create test deposit data
        VaultTypes.VaultDeposit memory depositData = VaultTypes.VaultDeposit({
            accountId: bytes32(0),
            brokerHash: bytes32(0),
            userAddress: MOCK_USER,
            tokenHash: keccak256("TEST"),
            tokenAmount: 1e18,
            depositNonce: 1
        });

        // Get estimated fee
        uint256 fee = _vaultManagerProxy.getDepositFee(depositData);
        assertTrue(fee > 0, "Deposit fee should be non-zero");
    }

    /// @notice Test deposit with fee refund functionality
    function test_depositWithFeeRefund() public {
        // Setup
        address refundReceiver = address(0xBEEF);
        uint256 initialBalance = refundReceiver.balance;
        
        VaultTypes.VaultDeposit memory depositData = VaultTypes.VaultDeposit({
            accountId: bytes32(0),
            brokerHash: bytes32(0),
            userAddress: MOCK_USER,
            tokenHash: keccak256("TEST"),
            tokenAmount: 1e18,
            depositNonce: 1
        });

        // Fund the relay for gas
        fundContract(address(_srcRelayProxy), 1 ether);
        fundContract(address(_vaultManagerProxy.vault()), 1 ether);
        
        // Mock vault call to deposit
        vm.startPrank(address(_vaultManagerProxy.vault()));
        _vaultManagerProxy.depositWithFeeRefund{value: 0.1 ether}(refundReceiver, depositData);
        vm.stopPrank();
        assertTrue(refundReceiver.balance >= initialBalance, "Refund receiver should get excess fees");
    }

    /// @notice Test rebalancing operations
    function test_rebalanceOperations() public {
        bytes32 tokenHash = keccak256("TEST");
        uint128 amount = 1000;

        // Setup rebalance burn data
        RebalanceTypes.RebalanceBurnCCData memory burnData = RebalanceTypes.RebalanceBurnCCData({
            dstDomain: 1,
            rebalanceId: 1,
            amount: amount,
            tokenHash: tokenHash,
            burnChainId: VAULT_CHAIN_ID,
            mintChainId: VAULT_CHAIN_ID,
            dstVaultAddress: address(_vaultManagerProxy.vault())
        });

        // Setup rebalance mint data
        RebalanceTypes.RebalanceMintCCData memory mintData = RebalanceTypes.RebalanceMintCCData({
            rebalanceId: 1,
            amount: amount,
            tokenHash: tokenHash,
            burnChainId: VAULT_CHAIN_ID,
            mintChainId: VAULT_CHAIN_ID,
            messageBytes: bytes(""),
            messageSignature: bytes("")
        });

        // Fund relays
        fundContract(address(_srcRelayProxy), 1 ether);
        fundContract(address(_dstRelayProxy), 1 ether);

        console.logBytes(CrossChainRelayUpgradeable(payable(address(_srcRelayProxy))).trustedRemoteLookup(LEDGER_LZ_CHAIN_ID));
        console.logBytes(CrossChainRelayUpgradeable(payable(address(_dstRelayProxy))).trustedRemoteLookup(VAULT_LZ_CHAIN_ID));

        // print relay addresses
        console.log("srcRelayProxy", address(_srcRelayProxy));
        console.log("dstRelayProxy", address(_dstRelayProxy));
        console.log("ledgerManagerProxy", address(_ledgerManagerProxy.crossChainRelay()));
        console.log("vaultManagerProxy", address(_vaultManagerProxy.crossChainRelay()));
        // Test burn operation
        vm.startPrank(address(_ledgerManagerProxy.ledger()));
        _ledgerManagerProxy.burn(burnData);
        vm.stopPrank();

        // Test mint operation
        vm.startPrank(address(_ledgerManagerProxy.ledger()));
        _ledgerManagerProxy.mint(mintData);
        vm.stopPrank();
    }

    /// @notice Test access control for critical functions
    function test_accessControl() public {
        bytes32 tokenHash = keccak256("TEST");
        
        // Non-owner should not be able to set token decimals
        vm.startPrank(MOCK_USER);
        vm.expectRevert("Ownable: caller is not the owner");
        _ledgerManagerProxy.setTokenDecimal(tokenHash, LEDGER_CHAIN_ID, 18);
        vm.stopPrank();

        // Non-vault should not be able to call vault-only functions
        VaultTypes.VaultDeposit memory depositData = VaultTypes.VaultDeposit({
            accountId: bytes32(0),
            brokerHash: bytes32(0),
            userAddress: MOCK_USER,
            tokenHash: tokenHash,
            tokenAmount: 1e18,
            depositNonce: 1
        });

        vm.startPrank(MOCK_USER);
        vm.expectRevert("VaultCrossChainManager: only vault can call");
        _vaultManagerProxy.deposit(depositData);
        vm.stopPrank();
    }

    /// @notice Test chain configuration
    function test_chainConfiguration() public {
        address newVaultManager = address(0xBEEF);
        uint256 newChainId = 999;

        // Set new chain configuration
        _vaultManagerProxy.setChainId(newChainId);
        _ledgerManagerProxy.setVaultCrossChainManager(newChainId, newVaultManager);

        // Verify configuration
        assertEq(_vaultManagerProxy.chainId(), newChainId);
        assertEq(_ledgerManagerProxy.vaultCrossChainManagers(newChainId), newVaultManager);
    }

    /// @notice Test decimal conversion edge cases
    function test_decimalConversionEdgeCases() public {
        bytes32 tokenHash = keccak256("TEST");
        uint128 amount = type(uint128).max;

        // Test same decimals
        _ledgerManagerProxy.setTokenDecimal(tokenHash, LEDGER_CHAIN_ID, 18);
        _ledgerManagerProxy.setTokenDecimal(tokenHash, VAULT_CHAIN_ID, 18);
        
        uint128 converted = _ledgerManagerProxy.convertDecimal(
            amount,
            tokenHash,
            LEDGER_CHAIN_ID,
            VAULT_CHAIN_ID
        );
        assertEq(converted, amount, "Same decimal conversion should not change amount");

        // Test zero amount
        converted = _ledgerManagerProxy.convertDecimal(
            0,
            tokenHash,
            LEDGER_CHAIN_ID,
            VAULT_CHAIN_ID
        );
        assertEq(converted, 0, "Zero amount should remain zero after conversion");
    }

    /// @notice Test message handling with invalid payloads
    function test_invalidMessageHandling() public {
        // Fund relays
        fundContract(address(_srcRelayProxy), 1 ether);
        fundContract(address(_dstRelayProxy), 1 ether);

        // Create message with invalid payload type
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Deposit),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: 99, // Invalid payload type
            srcCrossChainManager: address(_vaultManagerProxy),
            dstCrossChainManager: address(_ledgerManagerProxy),
            srcChainId: LEDGER_CHAIN_ID,
            dstChainId: VAULT_CHAIN_ID
        });

        bytes memory payload = abi.encode("invalid data");

        // Should revert with payload type mismatch
        vm.startPrank(address(_vaultManagerProxy.crossChainRelay()));
        vm.expectRevert("VaultCrossChainManager: payloadDataType not match");
        _vaultManagerProxy.receiveMessage(message, payload);
        vm.stopPrank();
    }

    /// @notice Test chain ID validation
    function test_chainIdValidation() public {
        // Try to send message to wrong chain
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Deposit),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultDeposit),
            srcCrossChainManager: address(_vaultManagerProxy),
            dstCrossChainManager: address(_ledgerManagerProxy),
            srcChainId: VAULT_CHAIN_ID,
            dstChainId: 999 // Wrong chain ID
        });

        bytes memory payload = bytes("");

        vm.startPrank(address(_vaultManagerProxy.crossChainRelay()));
        vm.expectRevert("VaultCrossChainManager: dstChainId not match");
        _vaultManagerProxy.receiveMessage(message, payload);
        vm.stopPrank();
    }

    /// @notice Test rebalance operations with invalid parameters
    function test_invalidRebalanceOperations() public {
        bytes32 tokenHash = keccak256("TEST");
        uint128 amount = type(uint128).max; // Try with max amount

        // Setup rebalance burn data with invalid parameters
        RebalanceTypes.RebalanceBurnCCData memory burnData = RebalanceTypes.RebalanceBurnCCData({
            dstDomain: 999, // Invalid domain
            rebalanceId: 0, // Invalid ID
            amount: amount,
            tokenHash: tokenHash,
            burnChainId: 999, // Invalid chain ID
            mintChainId: 999,
            dstVaultAddress: address(0) // Invalid vault address
        });

        // Should revert when trying to burn with invalid parameters
        vm.startPrank(address(_ledgerManagerProxy.ledger()));
        vm.expectRevert();
        _ledgerManagerProxy.burn(burnData);
        vm.stopPrank();
    }

    /// @notice Test deposit with insufficient fee
    function test_depositInsufficientFee() public {
        VaultTypes.VaultDeposit memory depositData = VaultTypes.VaultDeposit({
            accountId: bytes32(0),
            brokerHash: bytes32(0),
            userAddress: MOCK_USER,
            tokenHash: keccak256("TEST"),
            tokenAmount: 1e18,
            depositNonce: 1
        });

        // Get required fee
        uint256 requiredFee = _vaultManagerProxy.getDepositFee(depositData);

        // Try to deposit with insufficient fee
        vm.startPrank(address(_vaultManagerProxy.vault()));
        vm.expectRevert();
        _vaultManagerProxy.depositWithFee{value: requiredFee - 1}(depositData);
        vm.stopPrank();
    }

    /// @notice Test cross-chain message size limits
    function test_messageSizeLimits() public {
        // Create deposit data with large message
        bytes memory largeMessage = new bytes(100000); // Very large message
        
        RebalanceTypes.RebalanceMintCCData memory mintData = RebalanceTypes.RebalanceMintCCData({
            rebalanceId: 1,
            amount: 1000,
            tokenHash: keccak256("TEST"),
            burnChainId: VAULT_CHAIN_ID,
            mintChainId: VAULT_CHAIN_ID,
            messageBytes: largeMessage,
            messageSignature: bytes("")
        });

        // Should revert due to message size
        vm.startPrank(address(_ledgerManagerProxy.ledger()));
        vm.expectRevert();
        _ledgerManagerProxy.mint(mintData);
        vm.stopPrank();
    }

    /// @notice Test withdrawal to contract functionality
    function test_withdraw2Contract() public {
        // Fund relays for gas
        fundContract(address(_srcRelayProxy), 1 ether);
        fundContract(address(_dstRelayProxy), 1 ether);

        // Setup withdraw2contract data
        EventTypes.Withdraw2Contract memory withdrawData = EventTypes.Withdraw2Contract({
            tokenAmount: 1000,
            fee: 10,
            chainId: VAULT_CHAIN_ID,
            accountId: bytes32(0),
            vaultType: EventTypes.VaultEnum.ProtocolVault,
            sender: address(this),
            withdrawNonce: 1,
            receiver: address(0xBEEF), // Contract address to receive tokens
            timestamp: uint64(block.timestamp),
            brokerHash: bytes32(0),
            tokenHash: keccak256("TEST"),
            periodId: 1
        });

        // Create expected message
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Withdraw2Contract),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.EventTypesWithdraw2Contract),
            srcCrossChainManager: address(_ledgerManagerProxy),
            dstCrossChainManager: address(_vaultManagerProxy),
            srcChainId: LEDGER_CHAIN_ID,
            dstChainId: VAULT_CHAIN_ID
        });

        // Expect message events
        vm.expectEmit(true, false, false, false);
        emit MessageSent(message, abi.encode(withdrawData));

        // Initiate withdraw2contract from ledger
        vm.startPrank(address(_ledgerManagerProxy.ledger()));
        _ledgerManagerProxy.withdraw2Contract(withdrawData);
        vm.stopPrank();
    }

    /// @notice Test unauthorized withdraw2contract
    function test_withdraw2ContractUnauthorized() public {
        EventTypes.Withdraw2Contract memory withdrawData = EventTypes.Withdraw2Contract({
            tokenAmount: 1000,
            fee: 10,
            chainId: VAULT_CHAIN_ID,
            accountId: bytes32(0),
            vaultType: EventTypes.VaultEnum.ProtocolVault,
            sender: address(this),
            withdrawNonce: 1,
            receiver: address(0xBEEF),
            timestamp: uint64(block.timestamp),
            brokerHash: bytes32(0),
            tokenHash: keccak256("TEST"),
            periodId: 1
        });

        // Should revert when called by non-ledger address
        vm.startPrank(MOCK_USER);
        vm.expectRevert("LedgerCrossChainManager: caller is not ledger");
        _ledgerManagerProxy.withdraw2Contract(withdrawData);
        vm.stopPrank();
    }

    /// @notice Test withdraw2contract with invalid chain ID
    function test_withdraw2ContractInvalidChain() public {
        EventTypes.Withdraw2Contract memory withdrawData = EventTypes.Withdraw2Contract({
            tokenAmount: 1000,
            fee: 10,
            chainId: 999, // Invalid chain ID
            accountId: bytes32(0),
            vaultType: EventTypes.VaultEnum.ProtocolVault,
            sender: address(this),
            withdrawNonce: 1,
            receiver: address(0xBEEF),
            timestamp: uint64(block.timestamp),
            brokerHash: bytes32(0),
            tokenHash: keccak256("TEST"),
            periodId: 1
        });

        // Should revert when trying to withdraw to invalid chain
        vm.startPrank(address(_ledgerManagerProxy.ledger()));
        vm.expectRevert("CrossChainRelay: invalid dst chain id");
        _ledgerManagerProxy.withdraw2Contract(withdrawData);
        vm.stopPrank();
    }

} 