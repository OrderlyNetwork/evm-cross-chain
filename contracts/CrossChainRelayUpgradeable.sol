// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interface/IOrderlyCrossChain.sol";
import "./utils/OrderlyCrossChainMessage.sol";
import "./layerzero/lzApp/LzAppUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Data storage layout for the CrossChainRelay contract
/// @dev Separate contract to enforce proper storage layout with upgradeable contracts
contract CrossChainRelayDataLayout {
    /// @notice Mapping of addresses to their caller status (1 = trusted, 0 = untrusted)
    mapping(address => uint8) public _callers;

    /// @notice Maps native chain IDs to their corresponding LayerZero chain IDs
    mapping(uint256 => uint16) public _chainIdMapping;

    /// @notice Reverse mapping of LayerZero chain IDs to native chain IDs
    mapping(uint16 => uint256) public _lzChainIdMapping;

    /// @notice Maps chain IDs to their respective cross-chain manager contract addresses
    /// @dev Deprecated - No longer needed as manager address is stored directly
    mapping(uint256 => address) public _crossChainManagerMapping;

    /// @notice Maps chain IDs to their respective cross-chain relay contract addresses
    /// @dev Deprecated - No longer needed as relay addresses are handled by LayerZero
    mapping(uint256 => address) public _crossChainRelayMapping;

    /// @notice Maps message flow types to their gas limits for cross-chain operations
    mapping(uint8 => uint256) public _flowGasLimitMapping;

    /// @notice The chain ID where this contract is deployed
    uint256 public _currentChainId;

    /// @notice Address of the cross-chain manager (Vault or Ledger) on this chain
    address public _managerAddress;
}

/// @title CrossChainRelayUpgradeable
/// @notice A cross-chain messaging adapter that standardizes communication via LayerZero
/// @dev This contract acts as an abstraction layer over LayerZero's messaging protocol
contract CrossChainRelayUpgradeable is
    IOrderlyCrossChain,
    Initializable,
    OwnableUpgradeable,
    LzAppUpgradeable,
    UUPSUpgradeable,
    CrossChainRelayDataLayout
{
    /// @notice Emitted when a cross-chain message is received and processed
    /// @param method The type of cross-chain method being processed
    event MsgReceived(uint8 method);
    
    /// @notice Emitted when a ping message is received
    event Ping();
    
    /// @notice Emitted when a pong response is sent
    event Pong();

    using OrderlyCrossChainMessage for OrderlyCrossChainMessage.MessageV1;

    /// @dev Prevents initialization of the implementation contract
    constructor() {
        _disableInitializers();
    }

    /// @notice Restricts function access to trusted callers only
    /// @dev Throws if called by an address not marked as trusted in _callers mapping
    modifier onlyCaller() {
        require(_callers[msg.sender] == 1, "It is not a trusted caller.");
        _;
    }

    /// @notice Initializes the contract with LayerZero endpoint
    /// @dev Sets up initial trusted callers and initializes inherited contracts
    /// @param _endpoint The LayerZero endpoint address for cross-chain messaging
    function initialize(address _endpoint) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __LzApp_init(_endpoint);
        _callers[msg.sender] = 1;
        _callers[_endpoint] = 1;
    }

    /// @notice Updates the LayerZero endpoint address
    /// @dev Also marks the new endpoint as a trusted caller
    /// @param _endpoint New LayerZero endpoint address
    function updateEndpoint(address _endpoint) external onlyOwner {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
        _callers[_endpoint] = 1;
    }

    /// @dev Required override for UUPS proxy pattern
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Upgrades the implementation contract
    /// @dev Only callable by owner through proxy
    /// @param newImplementation Address of new implementation contract
    function upgradeTo(address newImplementation) public override onlyOwner onlyProxy {
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /// @dev Allows contract to receive native tokens for cross-chain fees
    receive() external payable {}

    /// @notice Withdraws native tokens from the contract
    /// @param to Recipient address
    /// @param amount Amount of native tokens to withdraw
    function withdrawNativeToken(address payable to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }

    /// @notice Withdraws ERC20 tokens from the contract
    /// @param token Token address
    /// @param to Recipient address
    /// @param amount Amount of tokens to withdraw
    function withdrawToken(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    /// @notice Sets the current chain ID
    /// @param chainId The current chain ID
    function setSrcChainId(uint256 chainId) external onlyOwner {
        _currentChainId = chainId;
    }

    /// @notice Adds a new trusted caller
    /// @param caller The caller address
    function addCaller(address caller) external onlyOwner {
        _callers[caller] = 1;
    }

    /// @notice Removes a trusted caller
    /// @param caller The caller address
    function removeCaller(address caller) external onlyOwner {
        _callers[caller] = 0;
    }

    /// @notice Adds a new chain ID mapping to LayerZero chain IDs
    /// @param chainId The raw chain ID
    /// @param lzChainId The LayerZero chain ID
    function addChainIdMapping(uint256 chainId, uint16 lzChainId) external onlyOwner {
        _chainIdMapping[chainId] = lzChainId;
        _lzChainIdMapping[lzChainId] = chainId;
    }

    /// @notice Sets the cross-chain manager address
    /// @dev Deprecated - No longer needed as manager address is stored directly
    /// @param chainId The chain ID
    /// @param crossChainManager The cross-chain manager address
    function addCrossChainManagerMapping(uint256 chainId, address crossChainManager) external onlyOwner {
        _crossChainManagerMapping[chainId] = crossChainManager;
    }

    /// @notice Sets the cross-chain relay address
    /// @dev Deprecated - No longer needed as relay addresses are handled by LayerZero
    /// @param chainId The chain ID
    /// @param crossChainRelay The cross-chain relay address
    function addCrossChainRelayMapping(uint256 chainId, address crossChainRelay) external onlyOwner {
        _crossChainRelayMapping[chainId] = crossChainRelay;
    }

    /// @notice Sets the manager address
    /// @param _address The manager address
    function setManagerAddress(address _address) external onlyOwner {
        _managerAddress = _address;
        _callers[_address] = 1;
    }

    /// @notice Sets the flow gas limit mapping
    /// @param flow The flow ID
    /// @param gasLimit The gas limit
    function addFlowGasLimitMapping(uint8 flow, uint256 gasLimit) external onlyOwner {
        _flowGasLimitMapping[flow] = gasLimit;
    }

    /// @notice Estimates the gas fee for a center message
    /// @param data The cross-chain meta message
    /// @param payload The payload
    /// @return The gas fee
    function estimateGasFee(OrderlyCrossChainMessage.MessageV1 memory data, bytes memory payload)
        public
        view
        override
        returns (uint256)
    {
        uint16 lzDstChainId = _chainIdMapping[data.dstChainId];
        bytes memory lzPayload = data.encodeMessageV1AndPayload(payload);
        require(lzDstChainId != 0, "CrossChainRelay: invalid dst chain id");
        uint16 version = 1;
        uint256 gasLimit = _flowGasLimitMapping[data.method];
        if (gasLimit == 0) {
            gasLimit = 3000000;
        }
        bytes memory adapterParams = abi.encodePacked(version, gasLimit);
        (uint256 nativeFee,) = lzEndpoint.estimateFees(lzDstChainId, address(this), lzPayload, false, adapterParams);
        return nativeFee;
    }

    /// @notice Sends a cross-chain message
    /// @param data The cross-chain meta message
    /// @param payload The payload
    function sendMessage(OrderlyCrossChainMessage.MessageV1 memory data, bytes memory payload)
        public
        payable
        override
        onlyCaller
    {
        bytes memory lzPayload = data.encodeMessageV1AndPayload(payload);
        uint16 lzDstChainId = _chainIdMapping[data.dstChainId];
        require(lzDstChainId != 0, "CrossChainRelay: invalid dst chain id");

        uint16 version = 1;
        uint256 gasLimit = _flowGasLimitMapping[data.method];
        if (gasLimit == 0) {
            gasLimit = 3000000;
        }
        bytes memory adapterParams = abi.encodePacked(version, gasLimit);

        (uint256 nativeFee,) = lzEndpoint.estimateFees(lzDstChainId, address(this), lzPayload, false, adapterParams);
        _lzSend(lzDstChainId, lzPayload, payable(address(this)), address(0), adapterParams, nativeFee);
        emit MessageSent(data, payload);
    }

    /// @notice Sends a cross-chain message with fee
    /// @param data The cross-chain meta message
    /// @param payload The payload
    function sendMessageWithFee(OrderlyCrossChainMessage.MessageV1 memory data, bytes memory payload)
        public
        payable
        override
        onlyCaller
    {
        bytes memory lzPayload = data.encodeMessageV1AndPayload(payload);
        uint16 lzDstChainId = _chainIdMapping[data.dstChainId];
        require(lzDstChainId != 0, "CrossChainRelay: invalid dst chain id");

        uint16 version = 1;
        uint256 gasLimit = _flowGasLimitMapping[data.method];
        if (gasLimit == 0) {
            gasLimit = 3000000;
        }
        bytes memory adapterParams = abi.encodePacked(version, gasLimit);

        _lzSend(lzDstChainId, lzPayload, payable(address(this)), address(0), adapterParams, msg.value);
        emit MessageSent(data, payload);
    }

    /// @notice Sends a cross-chain message with fee
    /// @param refundReceiver The receiver address for the lz fee refund
    /// @param data The cross-chain meta message
    /// @param payload The payload
    function sendMessageWithFeeRefund(
        address refundReceiver,
        OrderlyCrossChainMessage.MessageV1 memory data,
        bytes memory payload
    ) public payable override onlyCaller {
        bytes memory lzPayload = data.encodeMessageV1AndPayload(payload);
        uint16 lzDstChainId = _chainIdMapping[data.dstChainId];
        require(lzDstChainId != 0, "CrossChainRelay: invalid dst chain id");

        uint16 version = 1;
        uint256 gasLimit = _flowGasLimitMapping[data.method];
        if (gasLimit == 0) {
            gasLimit = 3000000;
        }
        bytes memory adapterParams = abi.encodePacked(version, gasLimit);

        _lzSend(lzDstChainId, lzPayload, payable(refundReceiver), address(0), adapterParams, msg.value);
        emit MessageSent(data, payload);
    }

    /// @notice Tests a function, sends ping to another chain
    /// @param dstChainId The destination chain ID
    function ping(uint256 dstChainId) internal {
        OrderlyCrossChainMessage.MessageV1 memory data = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Ping),
            option: 0,
            payloadDataType: 0,
            srcCrossChainManager: address(0),
            dstCrossChainManager: address(0),
            srcChainId: _currentChainId,
            dstChainId: dstChainId
        });
        sendMessage(data, bytes(""));
    }

    /// @notice Tests a function, sends ping to another chain and expects pong back
    /// @param dstChainId The destination chain ID
    function pingPong(uint256 dstChainId) external onlyOwner {
        OrderlyCrossChainMessage.MessageV1 memory data = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.PingPong),
            option: 0,
            payloadDataType: 0,
            srcCrossChainManager: address(0),
            dstCrossChainManager: address(0),
            srcChainId: _currentChainId,
            dstChainId: dstChainId
        });
        sendMessage(data, bytes(""));
    }

    /// @notice Receives a cross-chain message
    /// @param data The cross-chain meta message
    /// @param payload The payload
    function receiveMessage(OrderlyCrossChainMessage.MessageV1 memory data, bytes memory payload)
        public
        payable
        override
        onlyCaller
    {
        emit MessageReceived(data, payload);
        if (data.method == uint8(OrderlyCrossChainMessage.CrossChainMethod.PingPong)) {
            // send pong back;
            ping(data.srcChainId);
            emit Pong();
        } else if (data.method == uint8(OrderlyCrossChainMessage.CrossChainMethod.Ping)) {
            emit Ping();
        } else {
            IOrderlyCrossChainReceiver(_managerAddress).receiveMessage(data, payload);
        }
    }

    /// @notice Receives a cross-chain message from LayerZero endpoint
    /// @param _srcChainId The source chain ID
    /// @param _payload The payload
    function _blockingLzReceive(uint16 _srcChainId, bytes memory, uint64, bytes memory _payload)
        internal
        virtual
        override
    {
        uint256 rawSrcChainId = _lzChainIdMapping[_srcChainId];
        require(rawSrcChainId != 0, "CrossChainRelay: invalid src chain id");
        (OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload) =
            OrderlyCrossChainMessage.decodeMessageV1AndPayload(_payload);

        emit MsgReceived(message.method);

        receiveMessage(message, payload);
    }
}
