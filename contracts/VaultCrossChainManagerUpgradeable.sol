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

contract VaultCrossChainManagerDatalayout {
    // src chain id
    uint256 public chainId;
    // ledger chain id
    uint256 public ledgerChainId;
    // vault interface
    IVault public vault;
    // crosschain relay interface
    IOrderlyCrossChain public crossChainRelay;
    // map of chainId => LedgerCrossChainManager
    mapping(uint256 => address) public ledgerCrossChainManagers;

    // only vault
    modifier onlyVault() {
        require(msg.sender == address(vault), "VaultCrossChainManager: only vault can call");
        _;
    }

    // only relay
    modifier onlyRelay() {
        require(msg.sender == address(crossChainRelay), "VaultCrossChainManager: only crossChainRelay can call");
        _;
    }
}

contract VaultCrossChainManagerUpgradeable is
    IVaultCrossChainManager,
    IOrderlyCrossChainReceiver,
    OwnableUpgradeable,
    UUPSUpgradeable,
    VaultCrossChainManagerDatalayout
{
    /// @notice Initializes the contract.
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function upgradeTo(address newImplementation) public override onlyOwner {
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /// @notice Sets the chain ID.
    /// @param _chainId ID of the chain.
    function setChainId(uint256 _chainId) public onlyOwner {
        chainId = _chainId;
    }

    /// @notice Sets the vault address.
    /// @param _vault Address of the new vault.
    function setVault(address _vault) public onlyOwner {
        vault = IVault(_vault);
    }

    /// @notice Sets the cross-chain relay address.
    /// @param _crossChainRelay Address of the new cross-chain relay.
    function setCrossChainRelay(address _crossChainRelay) public onlyOwner {
        crossChainRelay = IOrderlyCrossChain(_crossChainRelay);
    }

    /// @notice Sets the ledger chain ID.
    /// @param _chainId ID of the ledger chain.
    function setLedgerCrossChainManager(uint256 _chainId, address _ledgerCrossChainManager) public onlyOwner {
        ledgerChainId = _chainId;
        ledgerCrossChainManagers[_chainId] = _ledgerCrossChainManager;
    }

    /// @notice receive message from relay, relay will call this function to send messages
    /// @param message message
    /// @param payload payload
    function receiveMessage(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload)
        external
        override
        onlyRelay
    {
        require(message.dstChainId == chainId, "VaultCrossChainManager: dstChainId not match");


        if (message.payloadDataType == uint8(OrderlyCrossChainMessage.PayloadDataType.EventTypesWithdrawData)){
            EventTypes.WithdrawData memory data = abi.decode(payload, (EventTypes.WithdrawData));
            // if token is CrossChainManagerTest
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
        } else if (message.payloadDataType == uint8(OrderlyCrossChainMessage.PayloadDataType.RebalanceBurnCCData)){
            RebalanceTypes.RebalanceBurnCCData memory data = abi.decode(payload, (RebalanceTypes.RebalanceBurnCCData));
            // call vault burn
            // TODO @zion
            vault.rebalanceBurn(data);
        } else if (message.payloadDataType == uint8(OrderlyCrossChainMessage.PayloadDataType.RebalanceMintCCData)){
            RebalanceTypes.RebalanceMintCCData memory data = abi.decode(payload, (RebalanceTypes.RebalanceMintCCData));
            // call vault mint
            // TODO @zion
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

    /// @notice Fetches the deposit fee based on deposit data.
    /// @param data Struct containing deposit data.
    function getDepositFee(VaultTypes.VaultDeposit memory data) public view override returns (uint256) {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Deposit),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultDeposit),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        bytes memory payload = abi.encode(data);

        return crossChainRelay.estimateGasFee(message, payload);
    }

    /// @notice Initiates a deposit to the vault.
    /// @param data Struct containing deposit data.
    function deposit(VaultTypes.VaultDeposit memory data) external override onlyVault{
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Deposit),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultDeposit),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        // encode message
        bytes memory payload = abi.encode(data);

        crossChainRelay.sendMessage(message, payload);
    }

    /// @notice Initiates a deposit to the vault along with native fees.
    /// @param data Struct containing deposit data.
    function depositWithFee(VaultTypes.VaultDeposit memory data) external payable override onlyVault{
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Deposit),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultDeposit),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        // encode message
        bytes memory payload = abi.encode(data);

        crossChainRelay.sendMessageWithFee{value: msg.value}(message, payload);
    }

    /// @notice Approves a cross-chain withdrawal from the ledger to the vault.
    /// @param data Struct containing withdrawal data.
    function withdraw(VaultTypes.VaultWithdraw memory data) external override onlyVault{
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.WithdrawFinish),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultWithdraw),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        // encode message
        bytes memory payload = abi.encode(data);

        crossChainRelay.sendMessage(message, payload);
    }

    /// @notice send burn finish back to ledger
    /// @param data Struct containing burn data.
    function burnFinish(RebalanceTypes.RebalanceBurnCCFinishData memory data) external override onlyVault {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.RebalanceBurnFinish),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.RebalanceBurnCCFinishData),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        // encode message
        bytes memory payload = abi.encode(data);

        crossChainRelay.sendMessage(message, payload);
    }

    /// @notice send mint finish back to ledger
    /// @param data Struct containing mint data.
    function mintFinish(RebalanceTypes.RebalanceMintCCFinishData memory data) external override onlyVault {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.RebalanceMintFinish),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.RebalanceMintCCFinishData),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        // encode message
        bytes memory payload = abi.encode(data);

        crossChainRelay.sendMessage(message, payload);
    }

    /// @notice send test withdraw back
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
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultWithdraw),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        // encode message
        bytes memory payload = abi.encode(data);

        crossChainRelay.sendMessage(message, payload);
    }

    /// @notice get role
    function getRole() external pure returns (string memory) {
        return "vault";
    }
}
