// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contract-evm/src/interface/IVault.sol";
import "contract-evm/src/library/types/VaultTypes.sol";
import "contract-evm/src/library/types/EventTypes.sol";
import "contract-evm/src/library/types/RebalanceTypes.sol";
import "contract-evm/src/library/Utils.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interface/IVaultCrossChainManager.sol";
import "./interface/IOrderlyCrossChain.sol";
import "./utils/OrderlyCrossChainMessage.sol";

/**
 * @title Vault Cross Chain Manager
 * @notice Manages cross-chain communication between Vaults and the Orderly Ledger
 * @dev This contract is responsible for:
 * - Processing deposits from vault to ledger
 * - Handling withdrawals from ledger to vault
 * - Managing token decimal conversions
 * - Coordinating rebalancing operations (mint/burn) with ledger
 */

/// @notice Storage layout for the Vault Cross Chain Manager
/// @dev Separate contract to enforce proper storage layout with upgradeable contracts
contract VaultCrossChainManagerDatalayout {
    /// @notice Chain ID where this contract is deployed (vault chain)
    uint256 public chainId;
    /// @notice Chain ID of the ledger chain
    uint256 public ledgerChainId;
    /// @notice Interface to the vault contract
    IVault public vault;
    /// @notice Interface to the cross-chain messaging relay
    IOrderlyCrossChain public crossChainRelay;
    /// @notice Maps chain IDs to their respective ledger cross-chain manager addresses
    mapping(uint256 => address) public ledgerCrossChainManagers;
    /// @notice Flag to indicate the version of the cross-chain relay
    /// @dev 0: LayerZeroV1, 1: LayerZeroV2
    uint8 public ccRelayOption;
    /// @notice Interface to the cross-chain messaging relay v2
    IOrderlyCrossChain public crossChainRelayV2;
    /// @notice Mapping of trusted cross-chain relay addresses
    mapping(address => bool) public trustRelays;

    /// @notice Ensures only the vault contract can call certain functions
    modifier onlyVault() {
        require(msg.sender == address(vault), "VaultCrossChainManager: only vault can call");
        _;
    }

    /// @notice Ensures only the cross-chain relay can call certain functions
    modifier onlyRelay() {
        require(trustRelays[msg.sender], "VaultCrossChainManager: only trusted CCRelay can call");
        _;
    }

    event SetCCRelayStatus(address indexed ccRelay, bool status);
    event SetCCRelayOption(uint8 ccRelayOption);
}

/// @title VaultCrossChainManagerUpgradeable
/// @notice Main contract for managing cross-chain operations on vault chains
/// @dev Handles message routing between vault and cross-chain relay
contract VaultCrossChainManagerUpgradeable is
    IVaultCrossChainManager,
    IOrderlyCrossChainReceiver,
    OwnableUpgradeable,
    UUPSUpgradeable,
    VaultCrossChainManagerDatalayout
{
    /// @notice Initializes the contract
    /// @dev Sets up the upgradeable contract with ownership and UUPS functionality
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /// @dev Required override for UUPS proxy pattern
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Upgrades the implementation contract
    /// @dev Only callable by owner through proxy
    /// @param newImplementation Address of new implementation contract
    function upgradeTo(address newImplementation) public override onlyOwner {
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    // ================================ ONLY OWNER FUNCTIONS ================================
    /// @notice Sets the chain ID for this contract instance
    /// @dev Critical for cross-chain message routing
    /// @param _chainId The chain ID where this contract is deployed
    function setChainId(uint256 _chainId) public onlyOwner {
        chainId = _chainId;
    }

    /// @notice Links this contract to the vault
    /// @dev The vault contract will be the only one allowed to initiate deposits
    /// @param _vault Address of the vault contract
    function setVault(address _vault) public onlyOwner {
        vault = IVault(_vault);
    }

    /// @notice Sets the cross-chain relay contract address
    /// @dev The relay handles the actual cross-chain message transmission
    /// @param _crossChainRelay Address of the cross-chain relay contract
    function setCrossChainRelay(address _crossChainRelay) public onlyOwner {
        crossChainRelay = IOrderlyCrossChain(_crossChainRelay);
    }

    /// @notice Sets the cross-chain relay contract address
    /// @dev The relay handles the actual cross-chain message transmission
    /// @param _crossChainRelayV2 Address of the cross-chain relay contract
    function setCrossChainRelayV2(address _crossChainRelayV2) public onlyOwner {
        crossChainRelayV2 = IOrderlyCrossChain(_crossChainRelayV2);
    }

    /// @notice Sets the status of a cross-chain relay
    /// @dev Allows the owner to enable or disable a relay
    /// @param _ccRelay The address of the cross-chain relay
    /// @param _status The new status of the relay (true for enabled, false for disabled)
    function setRelayStatus(address _ccRelay, bool _status) public onlyOwner {
        trustRelays[_ccRelay] = _status;
        emit SetCCRelayStatus(_ccRelay, _status);
    }

    /// @notice Sets the cross-chain relay option
    /// @dev Allows the owner to set the cross-chain relay option
    /// @param _ccRelayOption The new cross-chain relay option
    /// @dev 0: LayerZeroV1, 1: LayerZeroV2
    function setCCRelayOption(uint8 _ccRelayOption) public onlyOwner {
        ccRelayOption = _ccRelayOption;
        emit SetCCRelayOption(_ccRelayOption);
    }

    /// @notice Sets the ledger chain ID and its cross-chain manager address
    /// @dev Required for routing messages to the ledger
    /// @param _chainId The ledger chain ID
    /// @param _ledgerCrossChainManager Address of the ledger's cross-chain manager
    function setLedgerCrossChainManager(uint256 _chainId, address _ledgerCrossChainManager) public onlyOwner {
        ledgerChainId = _chainId;
        ledgerCrossChainManagers[_chainId] = _ledgerCrossChainManager;
    }

    // ================================ ONLY RELAY FUNCTIONS ================================
    /// @notice Handles incoming cross-chain messages from the relay
    /// @dev Routes messages based on their type and forwards to vault
    /// @param message The cross-chain message metadata
    /// @param payload The actual message data
    function receiveMessage(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload)
        external
        override
        onlyRelay
    {
        require(message.dstChainId == chainId, "VaultCrossChainManager: dstChainId not match");

        if (message.payloadDataType == uint8(OrderlyCrossChainMessage.PayloadDataType.EventTypesWithdrawData)) {
            EventTypes.WithdrawData memory data = abi.decode(payload, (EventTypes.WithdrawData));
            // Handle test token case
            if (keccak256(bytes(data.tokenSymbol)) == keccak256(bytes("CrossChainManagerTest"))) {
                _sendTestWithdrawBack();
            } else {
                VaultTypes.VaultWithdraw memory withdrawData = VaultTypes.VaultWithdraw({
                    accountId: data.accountId,
                    sender: data.sender,
                    receiver: data.receiver,
                    brokerHash: Utils.calculateStringHash(data.brokerId),
                    tokenHash: Utils.calculateStringHash(data.tokenSymbol),
                    tokenAmount: data.tokenAmount,
                    fee: data.fee,
                    withdrawNonce: data.withdrawNonce
                });
                _sendWithdrawToVault(withdrawData);
            }
        } else if (message.payloadDataType == uint8(OrderlyCrossChainMessage.PayloadDataType.EventTypesWithdraw2Contract)) {
            EventTypes.Withdraw2Contract memory data = abi.decode(payload, (EventTypes.Withdraw2Contract));
            VaultTypes.VaultWithdraw2Contract memory vaultData = VaultTypes.VaultWithdraw2Contract({
                vaultType: VaultTypes.VaultEnum(uint8(data.vaultType)),
                accountId: data.accountId,
                brokerHash: data.brokerHash,
                tokenHash: data.tokenHash,
                tokenAmount: data.tokenAmount,
                fee: data.fee,
                sender: data.sender,
                receiver: data.receiver,
                withdrawNonce: data.withdrawNonce,
                clientId: data.clientId
            });
            vault.withdraw2Contract(vaultData);
        } else if (message.payloadDataType == uint8(OrderlyCrossChainMessage.PayloadDataType.RebalanceBurnCCData)) {
            RebalanceTypes.RebalanceBurnCCData memory data = abi.decode(payload, (RebalanceTypes.RebalanceBurnCCData));
            vault.rebalanceBurn(data);
        } else if (message.payloadDataType == uint8(OrderlyCrossChainMessage.PayloadDataType.RebalanceMintCCData)) {
            RebalanceTypes.RebalanceMintCCData memory data = abi.decode(payload, (RebalanceTypes.RebalanceMintCCData));
            vault.rebalanceMint(data);
        } else {
            revert("VaultCrossChainManager: payloadDataType not match");
        }
    }

    /// @notice Triggers a withdrawal from the ledger.
    /// @param data Struct containing withdrawal data.
    function _sendWithdrawToVault(VaultTypes.VaultWithdraw memory data) internal {
        vault.withdraw(data);
    }


    // ================================ ONLY VAULT FUNCTIONS ================================
    /// @notice Fetches the deposit fee based on deposit data.
    /// @param data Struct containing deposit data.
    function getDepositFee(VaultTypes.VaultDeposit memory data) public view override returns (uint256) {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Deposit),
            option: ccRelayOption,
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultDeposit),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        bytes memory payload = abi.encode(data);

        return _estimateFee(message, payload);
    }

    /// @notice Estimates the gas fee for a message
    /// @dev Estimates the gas fee for a message to the cross-chain relay
    /// @param message The cross-chain message metadata
    /// @param payload The actual message payload
    function _estimateFee(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload) internal view returns (uint256) {
        if (message.option == uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZeroV1)) {
            return crossChainRelay.estimateGasFee(message, payload);
        } else if (message.option == uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZeroV2)) {
            return crossChainRelayV2.estimateGasFee(message, payload);
        } else {
            revert("VaultCrossChainManager: ccRelayOption not match");
        }
    }

    /// @notice Initiates a deposit to the ledger
    /// @dev Constructs and sends a cross-chain message through the relay
    /// @param data The deposit information including token and amount details
    function deposit(VaultTypes.VaultDeposit memory data) external override onlyVault {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Deposit),
            option: ccRelayOption,
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultDeposit),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        bytes memory payload = abi.encode(data);
        _sendMessage(message, payload);
    }

    /// @notice Initiates a deposit with native token fee payment
    /// @dev Allows paying cross-chain fees in native tokens (e.g., ETH)
    /// @param data The deposit information including token and amount details
    function depositWithFee(VaultTypes.VaultDeposit memory data) external payable override onlyVault {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Deposit),
            option: ccRelayOption,
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultDeposit),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        bytes memory payload = abi.encode(data);

        _sendMessageWithFee(message, payload);
    }

    /// @notice Initiates a deposit with fee refund capability
    /// @dev Allows specifying a refund address for unused cross-chain fees
    /// @param refundReceiver Address to receive any unused fee refunds
    /// @param data The deposit information including token and amount details
    function depositWithFeeRefund(address refundReceiver, VaultTypes.VaultDeposit memory data)
        external
        payable
        override
        onlyVault
    {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Deposit),
            option: ccRelayOption,
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultDeposit),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        bytes memory payload = abi.encode(data);

        _sendMessageWithFeeRefund(refundReceiver, message, payload);
    }

    /// @notice Sends withdrawal confirmation back to the ledger
    /// @dev Called after vault processes a withdrawal
    /// @param data The withdrawal information to confirm
    function withdraw(VaultTypes.VaultWithdraw memory data) external override onlyVault {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.WithdrawFinish),
            option: ccRelayOption,
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultWithdraw),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        bytes memory payload = abi.encode(data);

        _sendMessage(message, payload);
    }

    /// @notice Sends burn completion confirmation to the ledger
    /// @dev Called after vault completes a token burn operation
    /// @param data The burn completion information
    function burnFinish(RebalanceTypes.RebalanceBurnCCFinishData memory data) external override onlyVault {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.RebalanceBurnFinish),
            option: ccRelayOption,
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.RebalanceBurnCCFinishData),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        bytes memory payload = abi.encode(data);

        _sendMessage(message, payload);
    }

    /// @notice Sends mint completion confirmation to the ledger
    /// @dev Called after vault completes a token mint operation
    /// @param data The mint completion information
    function mintFinish(RebalanceTypes.RebalanceMintCCFinishData memory data) external override onlyVault {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.RebalanceMintFinish),
            option: ccRelayOption,
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.RebalanceMintCCFinishData),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        bytes memory payload = abi.encode(data);

        _sendMessage(message, payload);
    }



    /// @notice Sends a message
    /// @dev Sends a message to the cross-chain relay
    /// @param message The cross-chain message metadata
    /// @param payload The actual message payload
    function _sendMessage(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload) internal {
        if (message.option == uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZeroV1)) {
            crossChainRelay.sendMessage(message, payload);
        } else if (message.option == uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZeroV2)) {
            crossChainRelayV2.sendMessage(message, payload);
        } else {
            revert("VaultCrossChainManager: ccRelayOption not match");
        }
    }

    /// @notice Sends a message with fee payment
    /// @dev Allows paying cross-chain fees in native tokens (e.g., ETH)
    /// @param message The cross-chain message metadata
    /// @param payload The actual message payload
    function _sendMessageWithFee(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload) internal {
        if (message.option == uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZeroV1)) {
            crossChainRelay.sendMessageWithFee{value: msg.value}(message, payload);
        } else if (message.option == uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZeroV2)) {
            crossChainRelayV2.sendMessageWithFee{value: msg.value}(message, payload);
        } else {
            revert("VaultCrossChainManager: ccRelayOption not match");
        }
    }

    /// @notice Sends a message with fee refund capability
    /// @dev Allows specifying a refund address for unused cross-chain fees
    /// @param refundReceiver Address to receive any unused fee refunds
    /// @param message The cross-chain message metadata
    /// @param payload The actual message payload
    function _sendMessageWithFeeRefund(address refundReceiver, OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload) internal {
        if (message.option == uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZeroV1)) {
            crossChainRelay.sendMessageWithFeeRefund{value: msg.value}(refundReceiver, message, payload);
        } else if (message.option == uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZeroV2)) {
            crossChainRelayV2.sendMessageWithFeeRefund{value: msg.value}(refundReceiver, message, payload);
        } else {
            revert("VaultCrossChainManager: ccRelayOption not match");
        }
    }

    
    /// @notice Sends a test withdrawal confirmation back to the ledger
    /// @dev Used for testing cross-chain communication
    function _sendTestWithdrawBack() internal {
        VaultTypes.VaultWithdraw memory data = VaultTypes.VaultWithdraw({
            accountId: bytes32(0),
            sender: address(0),
            receiver: address(0),
            brokerHash: bytes32(0),
            tokenHash: Utils.calculateStringHash("CrossChainManagerTest"),
            tokenAmount: 0,
            fee: 0,
            withdrawNonce: 0
        });
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.WithdrawFinish),
            option: ccRelayOption,
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultWithdraw),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        bytes memory payload = abi.encode(data);

        _sendMessage(message, payload);
    }

    /// @notice Returns the role identifier for this contract
    /// @return A string indicating this is the vault cross-chain manager
    function getRole() external pure returns (string memory) {
        return "vault";
    }
}
