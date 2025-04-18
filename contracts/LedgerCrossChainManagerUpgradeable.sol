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

/**
 * @title Ledger Cross Chain Manager
 * @notice Manages cross-chain communication between the Orderly Ledger and Vaults
 * @dev This contract is responsible for:
 * - Processing cross-chain deposits from vaults to ledger
 * - Handling withdrawals from ledger to vaults
 * - Managing token decimal conversions between chains
 * - Coordinating rebalancing operations (mint/burn) across chains
 */

/// @notice Storage layout for the Ledger Cross Chain Manager
/// @dev Separate contract to enforce proper storage layout with upgradeable contracts
contract LedgerCrossChainManagerDatalayout {
    /// @notice Chain ID where this contract is deployed
    uint256 public chainId;
    
    /// @notice Interface to the main ledger contract
    ILedger public ledger;
    
    /// @notice Interface to the cross-chain messaging relay
    IOrderlyCrossChain public crossChainRelay;
    
    /// @notice Interface to manage operator permissions
    IOperatorManager public operatorManager;
    
    /// @notice Maps chain IDs to their respective vault cross-chain manager addresses
    mapping(uint256 => address) public vaultCrossChainManagers;

    /// @notice Maps token hash and chain ID to token decimals for amount conversion
    /// @dev Format: tokenHash => chainId => decimals
    mapping(bytes32 => mapping(uint256 => uint128)) public tokenDecimalMapping;
    
    /// @notice Flag to indicate the version of the cross-chain relay for each chain
    /// @dev chainId => relay option
    /// @dev version number: 0 = LayerZeroV1, 1 = LayerZeroV2
    mapping(uint256 => uint8) public ccRelayOption;

    /// @notice Mapping of enabled cross-chain relay addresses
    mapping(address => bool) public enabledRelays;

    /// @notice Interface to the cross-chain messaging relay v2
    IOrderlyCrossChain public crossChainRelayV2;

    /// @notice Ensures only the ledger contract can call certain functions
    modifier onlyLedger() {
        require(msg.sender == address(ledger), "LedgerCrossChainManager: caller is not ledger");
        _;
    }

    /// @notice Ensures only the cross-chain relay can call certain functions
    modifier onlyEnabledRelay() {
        require(enabledRelays[msg.sender], "LedgerCrossChainManager: only enabled CCRelay can call");
        _;
    }

    event SetCCRelayStatus(address indexed ccRelay, bool status);
    event SetCCRelayOption(uint256 chainId, uint8 ccRelayOption);
}

/// @notice Handles token decimal conversions between different chains
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
 * @title Ledger Cross Chain Manager Implementation
 * @notice Manages cross-chain operations between Ledger and Vaults
 * @dev This contract should only be deployed on the main chain (where ledger exists)
 *
 * Flow: Ledger -> LedgerCrossChainManager -> CrossChainRelay -> VaultCrossChainManager -> Vault
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
    /// @notice Emitted when a deposit is successfully received and processed
    event DepositReceived(AccountTypes.AccountDeposit data);
    
    /// @notice Emitted when a test withdrawal operation completes
    event TestWithdrawDone();

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
    function upgradeTo(address newImplementation) public override onlyOwner onlyProxy {
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    // ================================ ONLY OWNER FUNCTIONS ================================
    /// @notice Sets the chain ID for this contract instance
    /// @dev Critical for cross-chain message routing and token decimal conversions
    /// @param _chainId The chain ID where this contract is deployed
    function setChainId(uint256 _chainId) external onlyOwner {
        chainId = _chainId;
    }

    /// @notice Links this contract to the Orderly Ledger
    /// @dev The Ledger contract will be the only one allowed to initiate withdrawals
    /// @param _ledger Address of the Orderly Ledger contract
    function setLedger(address _ledger) external onlyOwner {
        ledger = ILedger(_ledger);
    }

    /// @notice Sets the cross-chain relay contract address
    /// @dev The relay handles the actual cross-chain message transmission via LayerZero
    /// @param _crossChainRelay Address of the cross-chain relay contract
    function setCrossChainRelay(address _crossChainRelay) external onlyOwner {
        crossChainRelay = IOrderlyCrossChain(_crossChainRelay);
    }

    /// @notice Sets the cross-chain relay contract address
    /// @dev The relay handles the actual cross-chain message transmission via LayerZero
    /// @param _crossChainRelayV2 Address of the cross-chain relay contract v2
    function setCrossChainRelayV2(address _crossChainRelayV2) external onlyOwner {
        crossChainRelayV2 = IOrderlyCrossChain(_crossChainRelayV2);
    }

        /// @notice Sets the status of a cross-chain relay
    /// @dev Allows the owner to enable or disable a relay
    /// @param _ccRelay The address of the cross-chain relay
    /// @param _status The new status of the relay (true for enabled, false for disabled)
    function setRelayStatus(address _ccRelay, bool _status) public onlyOwner {
        enabledRelays[_ccRelay] = _status;
        emit SetCCRelayStatus(_ccRelay, _status);
    }

    /// @notice Sets the cross-chain relay option
    /// @dev Allows the owner to set the cross-chain relay option
    /// @param _chainId The chain ID of vault chain
    /// @param _ccRelayOption The new cross-chain relay option
    /// @dev 0: LayerZeroV1, 1: LayerZeroV2
    function setCCRelayOption(uint256 _chainId, uint8 _ccRelayOption) public onlyOwner {
        ccRelayOption[_chainId] = _ccRelayOption;
        emit SetCCRelayOption(_chainId, _ccRelayOption);
    }

    /// @notice Sets the operator manager contract address
    /// @dev The operator manager handles permissions and operational controls
    /// @param _operatorManager Address of the operator manager contract
    function setOperatorManager(address _operatorManager) external onlyOwner {
        operatorManager = IOperatorManager(_operatorManager);
    }

    /// @notice Maps a chain ID to its vault cross-chain manager address
    /// @dev Required for routing messages to the correct vault on each chain
    /// @param _chainId The chain ID where the vault exists
    /// @param _vaultCrossChainManager Address of the vault's cross-chain manager
    function setVaultCrossChainManager(uint256 _chainId, address _vaultCrossChainManager) external onlyOwner {
        vaultCrossChainManagers[_chainId] = _vaultCrossChainManager;
    }

    /// @notice Sets the decimal places for a token on a specific chain
    /// @dev Critical for accurate token amount conversions between chains
    /// @param tokenHash The hash of the token symbol
    /// @param tokenChainId The chain ID where the token exists
    /// @param decimal The number of decimal places for the token
    function setTokenDecimal(bytes32 tokenHash, uint256 tokenChainId, uint128 decimal) external onlyOwner {
        _setTokenDecimal(tokenHash, tokenChainId, decimal);
    }

    /// @notice Processes a deposit from a vault chain
    /// @dev Emits DepositReceived event and forwards to ledger
    /// @param data The deposit information including account and token details
    function _deposit(AccountTypes.AccountDeposit memory data) internal {
        emit DepositReceived(data);
        ledger.accountDeposit(data);
    }

    // ================================ ONLY RELAY FUNCTIONS ================================
    /// @notice Handles incoming cross-chain messages from the relay
    /// @dev Routes messages based on their type and performs necessary decimal conversions
    /// @param message The cross-chain message metadata
    /// @param payload The actual message data
    function receiveMessage(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload)
        external
        override
        onlyEnabledRelay
    {
        require(message.dstChainId == chainId, "LedgerCrossChainManager: dstChainId not match");

        if (message.payloadDataType == uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultDeposit)) {
            // Handle deposit from vault
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
            _deposit(depositData);
        } else if (message.payloadDataType == uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultWithdraw)) {
            // Handle withdrawal confirmation from vault
            VaultTypes.VaultWithdraw memory data = abi.decode(payload, (VaultTypes.VaultWithdraw));
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
            _withdrawFinish(withdrawData);
        } else if (message.payloadDataType == uint8(OrderlyCrossChainMessage.PayloadDataType.RebalanceBurnCCFinishData)) {
            // Handle burn completion from vault
            RebalanceTypes.RebalanceBurnCCFinishData memory data =
                abi.decode(payload, (RebalanceTypes.RebalanceBurnCCFinishData));
            uint128 cvtTokenAmount = convertDecimal(data.amount, data.tokenHash, message.srcChainId, chainId);
            data.amount = cvtTokenAmount;
            ledger.rebalanceBurnFinish(data);
        } else if (message.payloadDataType == uint8(OrderlyCrossChainMessage.PayloadDataType.RebalanceMintCCFinishData)) {
            // Handle mint completion from vault
            RebalanceTypes.RebalanceMintCCFinishData memory data =
                abi.decode(payload, (RebalanceTypes.RebalanceMintCCFinishData));
            uint128 cvtTokenAmount = convertDecimal(data.amount, data.tokenHash, message.srcChainId, chainId);
            data.amount = cvtTokenAmount;
            ledger.rebalanceMintFinish(data);
        } else {
            revert("LedgerCrossChainManager: payloadDataType not match");
        }
    }

    // ================================ ONLY LEDGER FUNCTIONS ================================
    /// @notice send a cross-chain withdrawal from the ledger to the vault.
    /// @param data Struct containing withdrawal data.
    function withdraw(EventTypes.WithdrawData memory data) external override onlyLedger {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Withdraw),
            option: ccRelayOption[data.chainId],
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

        _sendMessage(message, payload);
    }

    /// @notice send a cross-chain withdrawal from the ledger to the vault. but only withdraw to contract address
    /// @param data Struct containing withdrawal data.
    function withdraw2Contract(EventTypes.Withdraw2Contract memory data) external override onlyLedger {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Withdraw2Contract),
            option: ccRelayOption[data.chainId],
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.EventTypesWithdraw2Contract),
            srcCrossChainManager: address(this),
            dstCrossChainManager: vaultCrossChainManagers[data.chainId],
            srcChainId: chainId,
            dstChainId: data.chainId
        });

        // convert token amount to dst chain decimal
        uint128 cvtTokenAmount =
            convertDecimal(data.tokenAmount, data.tokenHash, chainId, data.chainId);
        uint128 cvtFeeAmount =
            convertDecimal(data.fee, data.tokenHash, chainId, data.chainId);
        data.tokenAmount = cvtTokenAmount;
        data.fee = cvtFeeAmount;

        bytes memory payload = abi.encode(data);

        _sendMessage(message, payload);
    }


    /// @notice Initiates a token burn operation on a vault chain
    /// @dev Converts token amounts to vault chain decimals before sending
    /// @param burnData Contains burn request details including amount and chain info
    function burn(RebalanceTypes.RebalanceBurnCCData memory burnData) external override onlyLedger {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.RebalanceBurn),
            option: ccRelayOption[burnData.burnChainId],
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.RebalanceBurnCCData),
            srcCrossChainManager: address(this),
            dstCrossChainManager: vaultCrossChainManagers[burnData.burnChainId],
            srcChainId: chainId,
            dstChainId: burnData.burnChainId
        });

        // Convert token amount to destination chain decimals
        uint128 cvtTokenAmount =
            convertDecimal(burnData.amount, burnData.tokenHash, chainId, burnData.burnChainId);
        burnData.amount = cvtTokenAmount;

        bytes memory payload = abi.encode(burnData);

        _sendMessage(message, payload);
    }

    /// @notice Initiates a token mint operation on a vault chain
    /// @dev Converts token amounts to vault chain decimals before sending
    /// @param mintData Contains mint request details including amount and chain info
    function mint(RebalanceTypes.RebalanceMintCCData memory mintData) external override onlyLedger {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.RebalanceMint),
            option: ccRelayOption[mintData.mintChainId],
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.RebalanceMintCCData),
            srcCrossChainManager: address(this),
            dstCrossChainManager: vaultCrossChainManagers[mintData.mintChainId],
            srcChainId: chainId,
            dstChainId: mintData.mintChainId
        });

        // Convert token amount to destination chain decimals
        uint128 cvtTokenAmount =
            convertDecimal(mintData.amount, mintData.tokenHash, chainId, mintData.mintChainId);
        mintData.amount = cvtTokenAmount;

        bytes memory payload = abi.encode(mintData);

        _sendMessage(message, payload);
    }

    /// @notice Sends a message to the cross-chain relay
    /// @dev Selects the correct cross-chain relay version based on the message option
    /// @param message The cross-chain message metadata
    /// @param payload The actual message data
    function _sendMessage(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload) internal {
        if (message.option == uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZeroV1)) {
            crossChainRelay.sendMessage(message, payload);
        } else if (message.option == uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZeroV2)) {
            crossChainRelayV2.sendMessage(message, payload);
        }
    }

     /// @notice Processes a withdrawal completion message
    /// @dev Internal function called when a withdrawal is confirmed by vault
    /// @param message The withdrawal completion details
    function _withdrawFinish(AccountTypes.AccountWithdraw memory message) internal {
        ledger.accountWithDrawFinish(message);
    }


    // ================================ ONLY FOR TEST ================================
    /// @notice Sends a test withdrawal message to verify cross-chain connectivity
    /// @dev Uses a special token symbol "CrossChainManagerTest" for testing
    /// @param dstChainId The destination chain to test connectivity with
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
            option: ccRelayOption[data.chainId],
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.EventTypesWithdrawData),
            srcCrossChainManager: address(this),
            dstCrossChainManager: vaultCrossChainManagers[data.chainId],
            srcChainId: chainId,
            dstChainId: data.chainId
        });

        // Convert amounts to destination chain decimals
        uint128 cvtTokenAmount =
            convertDecimal(data.tokenAmount, Utils.calculateStringHash(data.tokenSymbol), chainId, data.chainId);
        uint128 cvtFeeAmount =
            convertDecimal(data.fee, Utils.calculateStringHash(data.tokenSymbol), chainId, data.chainId);
        data.tokenAmount = cvtTokenAmount;
        data.fee = cvtFeeAmount;

        bytes memory payload = abi.encode(data);
        _sendMessage(message, payload);
    }

   

    /// @notice Returns the role identifier for this contract
    /// @return A string indicating this is the ledger cross-chain manager
    function getRole() external pure returns (string memory) {
        return "ledger";
    }
}
