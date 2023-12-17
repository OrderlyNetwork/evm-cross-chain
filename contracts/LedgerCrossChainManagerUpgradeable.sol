// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "contract-evm/src/interface/ILedger.sol";
import "contract-evm/src/interface/IOperatorManager.sol";
import "contract-evm/src/library/types/AccountTypes.sol";
import "contract-evm/src/library/types/EventTypes.sol";
import "contract-evm/src/library/types/VaultTypes.sol";
import "contract-evm/src/library/types/RebalanceTypes.sol";
import "contract-evm/src/library/Utils.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interface/ILedgerCrossChainManager.sol";
import "./interface/IOrderlyCrossChain.sol";
import "./utils/OrderlyCrossChainMessage.sol";

contract LedgerCrossChainManagerDatalayout {
    // chain id of this contract
    uint256 public chainId;
    // ledger Interface
    ILedger public ledger;
    // crosschain relay interface
    IOrderlyCrossChain public crossChainRelay;
    // operatorManager Interface
    IOperatorManager public operatorManager;
    // map of chainId => VaultCrossChainManager
    mapping(uint256 => address) public vaultCrossChainManagers;

    mapping(bytes32 => mapping(uint256 => uint128)) public tokenDecimalMapping;

    modifier onlyLedger() {
        require(msg.sender == address(ledger), "LedgerCrossChainManager: caller is not ledger");
        _;
    }

    modifier onlyRelay() {
        require(msg.sender == address(crossChainRelay), "LedgerCrossChainManager: caller is not crossChainRelay");
        _;
    }
}

contract DecimalManager is LedgerCrossChainManagerDatalayout {
    /// @notice Sets the token decimal.
    /// @param tokenHash token hash
    /// @param tokenChainId token chain id
    /// @param decimal decimal
    function _setTokenDecimal(bytes32 tokenHash, uint256 tokenChainId, uint128 decimal) internal {
        tokenDecimalMapping[tokenHash][tokenChainId] = decimal;
    }

    /// @notice Gets the token decimal.
    /// @param tokenHash token hash
    /// @param tokenChainId token chain id
    function getTokenDecimal(bytes32 tokenHash, uint256 tokenChainId) internal view returns (uint128) {
        return tokenDecimalMapping[tokenHash][tokenChainId];
    }

    /// @notice convert token amount to dst chain decimal
    /// @param tokenAmount token amount
    /// @param srcDecimal src chain decimal
    /// @param dstDecimal dst chain decimal
    function convertDecimal(uint128 tokenAmount, uint128 srcDecimal, uint128 dstDecimal)
        internal
        pure
        returns (uint128)
    {
        if (srcDecimal == dstDecimal) {
            return tokenAmount;
        } else if (srcDecimal > dstDecimal) {
            return tokenAmount / uint128(10 ** (srcDecimal - dstDecimal));
        } else {
            return tokenAmount * uint128(10 ** (dstDecimal - srcDecimal));
        }
    }

    /// @notice convert token amount to dst chain decimal
    /// @param tokenAmount token amount
    /// @param tokenHash token hash
    /// @param srcChainId src chain id
    /// @param dstChainId dst chain id
    function convertDecimal(uint128 tokenAmount, bytes32 tokenHash, uint256 srcChainId, uint256 dstChainId)
        public
        view
        returns (uint128)
    {
        uint128 srcDecimal = getTokenDecimal(tokenHash, srcChainId);
        uint128 dstDecimal = getTokenDecimal(tokenHash, dstChainId);
        return convertDecimal(tokenAmount, srcDecimal, dstDecimal);
    }
}

/**
 * CrossChainManager is responsible for executing cross-chain tx.
 * This contract should only have one in main-chain (avalanche)
 *
 * Ledger(manager addr, chain id) -> LedgerCrossChainManager -> OrderlyCrossChain -> VaultCrossChainManager(Identified by chain id) -> Vault
 *
 */
contract LedgerCrossChainManagerUpgradeable is
    IOrderlyCrossChainReceiver,
    ILedgerCrossChainManager,
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    LedgerCrossChainManagerDatalayout,
    DecimalManager
{
    event DepositReceived(AccountTypes.AccountDeposit data);
    event TestWithdrawDone();

    /// @notice Initializes the contract.
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function upgradeTo(address newImplementation) public override onlyOwner {
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /// @notice set chain id
    /// @param _chainId chain id
    function setChainId(uint256 _chainId) external onlyOwner {
        chainId = _chainId;
    }

    /// @notice set ledger
    /// @param _ledger ledger address
    function setLedger(address _ledger) external onlyOwner {
        ledger = ILedger(_ledger);
    }

    /// @notice set crossChainRelay
    /// @param _crossChainRelay crossChainRelay address
    function setCrossChainRelay(address _crossChainRelay) external onlyOwner {
        crossChainRelay = IOrderlyCrossChain(_crossChainRelay);
    }

    /// @notice set operatorManager
    /// @param _operatorManager operatorManager address
    function setOperatorManager(address _operatorManager) external onlyOwner {
        operatorManager = IOperatorManager(_operatorManager);
    }

    /// @notice set vaultCrossChainManager
    /// @param _chainId chain id
    /// @param _vaultCrossChainManager vaultCrossChainManager address
    function setVaultCrossChainManager(uint256 _chainId, address _vaultCrossChainManager) external onlyOwner {
        vaultCrossChainManagers[_chainId] = _vaultCrossChainManager;
    }

    /// @notice set token decimal
    /// @param tokenHash ERC20 token hash
    /// @param tokenChainId token chain id
    /// @param decimal token decimal
    function setTokenDecimal(bytes32 tokenHash, uint256 tokenChainId, uint128 decimal) external onlyOwner {
        _setTokenDecimal(tokenHash, tokenChainId, decimal);
    }

    /// @notice send a cross-chain deposit
    /// @param data deposit data
    function deposit(AccountTypes.AccountDeposit memory data) internal {
        emit DepositReceived(data);
        ledger.accountDeposit(data);
    }

    /// @notice receive message from relay, relay will call this function to send messages
    /// @param message message
    /// @param payload payload
    function receiveMessage(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload)
        external
        override
        onlyRelay
    {
        require(message.dstChainId == chainId, "LedgerCrossChainManager: dstChainId not match");
        if (message.payloadDataType == uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultDeposit)) {
            VaultTypes.VaultDeposit memory data = abi.decode(payload, (VaultTypes.VaultDeposit));

            uint128 cvtTokenAmount = convertDecimal(data.tokenAmount, data.tokenHash, message.srcChainId, chainId);

            AccountTypes.AccountDeposit memory depositData = AccountTypes.AccountDeposit({
                accountId: data.accountId,
                brokerHash: data.brokerHash,
                userAddress: data.userAddress,
                tokenHash: data.tokenHash,
                tokenAmount: cvtTokenAmount,
                srcChainId: message.srcChainId,
                srcChainDepositNonce: data.depositNonce
            });

            deposit(depositData);
        } else if (message.payloadDataType == uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultWithdraw)) {
            VaultTypes.VaultWithdraw memory data = abi.decode(payload, (VaultTypes.VaultWithdraw));

            // handle test withdraw
            if (data.tokenHash == Utils.calculateStringHash("CrossChainManagerTest")) {
                emit TestWithdrawDone();
                return;
            }

            uint128 cvtTokenAmount = convertDecimal(data.tokenAmount, data.tokenHash, message.srcChainId, chainId);
            uint128 cvtFeeAmount = convertDecimal(data.fee, data.tokenHash, message.srcChainId, chainId);

            AccountTypes.AccountWithdraw memory withdrawData = AccountTypes.AccountWithdraw({
                accountId: data.accountId,
                sender: data.sender,
                receiver: data.receiver,
                brokerHash: data.brokerHash,
                tokenHash: data.tokenHash,
                tokenAmount: cvtTokenAmount,
                fee: cvtFeeAmount,
                chainId: message.srcChainId,
                withdrawNonce: data.withdrawNonce
            });

            withdrawFinish(withdrawData);
        } else if (message.payloadDataType == uint8(OrderlyCrossChainMessage.PayloadDataType.RebalanceBurnCCFinishData))
        {
            RebalanceTypes.RebalanceBurnCCFinishData memory data =
                abi.decode(payload, (RebalanceTypes.RebalanceBurnCCFinishData));
            uint128 cvtTokenAmount = convertDecimal(data.amount, data.tokenHash, message.srcChainId, chainId);
            data.amount = cvtTokenAmount;

            ledger.rebalanceBurnFinish(data);
        } else if (message.payloadDataType == uint8(OrderlyCrossChainMessage.PayloadDataType.RebalanceMintCCFinishData))
        {
            RebalanceTypes.RebalanceMintCCFinishData memory data =
                abi.decode(payload, (RebalanceTypes.RebalanceMintCCFinishData));
            uint128 cvtTokenAmount = convertDecimal(data.amount, data.tokenHash, message.srcChainId, chainId);
            data.amount = cvtTokenAmount;

            ledger.rebalanceMintFinish(data);
        } else {
            revert("LedgerCrossChainManager: payloadDataType not match");
        }
    }

    /// @notice send a cross-chain withdrawal from the ledger to the vault.
    /// @param data Struct containing withdrawal data.
    function withdraw(EventTypes.WithdrawData memory data) external override onlyLedger {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Withdraw),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.EventTypesWithdrawData),
            srcCrossChainManager: address(this),
            dstCrossChainManager: vaultCrossChainManagers[data.chainId],
            srcChainId: chainId,
            dstChainId: data.chainId
        });

        // convert token amount to dst chain decimal
        uint128 cvtTokenAmount =
            convertDecimal(data.tokenAmount, Utils.calculateStringHash(data.tokenSymbol), chainId, data.chainId);
        uint128 cvtFeeAmount =
            convertDecimal(data.fee, Utils.calculateStringHash(data.tokenSymbol), chainId, data.chainId);
        data.tokenAmount = cvtTokenAmount;
        data.fee = cvtFeeAmount;

        bytes memory payload = abi.encode(data);

        crossChainRelay.sendMessage(message, payload);
    }

    function burn(RebalanceTypes.RebalanceBurnCCData memory burnData) external override onlyLedger {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.RebalanceBurn),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.RebalanceBurnCCData),
            srcCrossChainManager: address(this),
            dstCrossChainManager: vaultCrossChainManagers[burnData.burnChainId],
            srcChainId: chainId,
            dstChainId: burnData.burnChainId
        });

        // convert token amount to dst chain decimal
        uint128 cvtTokenAmount =
            convertDecimal(burnData.amount, burnData.tokenHash, chainId, burnData.burnChainId);
        burnData.amount = cvtTokenAmount;

        bytes memory payload = abi.encode(burnData);

        crossChainRelay.sendMessage(message, payload);
    }

    function mint(RebalanceTypes.RebalanceMintCCData memory mintData) external override onlyLedger {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.RebalanceMint),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.RebalanceMintCCData),
            srcCrossChainManager: address(this),
            dstCrossChainManager: vaultCrossChainManagers[mintData.mintChainId],
            srcChainId: chainId,
            dstChainId: mintData.mintChainId
        });

        // convert token amount to dst chain decimal
        uint128 cvtTokenAmount =
            convertDecimal(mintData.amount, mintData.tokenHash, chainId, mintData.mintChainId);
        mintData.amount = cvtTokenAmount;

        bytes memory payload = abi.encode(mintData);

        crossChainRelay.sendMessage(message, payload);
    }

    /// @notice send a test cross-chain withdrawal for connection test
    /// @param dstChainId destination chain id
    function sendTestWithdraw(uint256 dstChainId) external onlyOwner {
        EventTypes.WithdrawData memory data = EventTypes.WithdrawData({
            tokenAmount: 100,
            fee: 0,
            chainId: dstChainId,
            accountId: bytes32(""),
            r: bytes32(""),
            s: bytes32(""),
            v: 1,
            sender: address(0x126),
            withdrawNonce: 1,
            receiver: address(0x127),
            timestamp: 1,
            brokerId: "brokerId",
            tokenSymbol: "CrossChainManagerTest"
        });
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Withdraw),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.EventTypesWithdrawData),
            srcCrossChainManager: address(this),
            dstCrossChainManager: vaultCrossChainManagers[data.chainId],
            srcChainId: chainId,
            dstChainId: data.chainId
        });

        // convert token amount to dst chain decimal
        uint128 cvtTokenAmount =
            convertDecimal(data.tokenAmount, Utils.calculateStringHash(data.tokenSymbol), chainId, data.chainId);
        uint128 cvtFeeAmount =
            convertDecimal(data.fee, Utils.calculateStringHash(data.tokenSymbol), chainId, data.chainId);
        data.tokenAmount = cvtTokenAmount;
        data.fee = cvtFeeAmount;

        bytes memory payload = abi.encode(data);

        crossChainRelay.sendMessage(message, payload);
    }

    /// @notice withdraw finished
    /// @param message withdraw message
    function withdrawFinish(AccountTypes.AccountWithdraw memory message) internal {
        ledger.accountWithDrawFinish(message);
    }

    /// @notice get role
    function getRole() external pure returns (string memory) {
        return "ledger";
    }
}
