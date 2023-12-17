// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interface/IOrderlyCrossChain.sol";
import "./utils/OrderlyCrossChainMessage.sol";
import "./layerzero/lzApp/LzAppUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Datalayout for the Cross Chain Relay
contract CrossChainRelayDataLayout {
    // A mapping to track trusted callers
    mapping(address => uint8) public _callers;

    // Raw chain id to layerzero chain id mapping
    mapping(uint256 => uint16) public _chainIdMapping;

    // layerzero chain id to raw chain id mapping
    mapping(uint16 => uint256) public _lzChainIdMapping;

    // chain id to cross chain manager contract address
    mapping(uint256 => address) public _crossChainManagerMapping;

    // chain id to cross chain relay contract address
    mapping(uint256 => address) public _crossChainRelayMapping;

    // flow to gas limit mapping
    mapping(uint8 => uint256) public _flowGasLimitMapping;

    // The Current Chain ID
    uint256 public _currentChainId;

    // the manager address
    address public _managerAddress;
}

contract CrossChainRelayUpgradeable is
    IOrderlyCrossChain,
    Initializable,
    OwnableUpgradeable,
    LzAppUpgradeable,
    UUPSUpgradeable,
    CrossChainRelayDataLayout
{
    event MsgReceived(uint8);
    event Ping();
    event Pong();

    using OrderlyCrossChainMessage for OrderlyCrossChainMessage.MessageV1;

    constructor() {
        _disableInitializers();
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyCaller() {
        require(_callers[msg.sender] == 1, "It is not a trusted caller.");
        _;
    }

    /// @notice initialize the contract with the endpoint address
    /// @param _endpoint the endpoint address
    function initialize(address _endpoint) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __LzApp_init(_endpoint);
        _callers[msg.sender] = 1;
        _callers[_endpoint] = 1;
    }

    /// @notice update the endpoint address
    /// @param _endpoint the endpoint address
    function updateEndpoint(address _endpoint) external onlyOwner {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
        _callers[_endpoint] = 1;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function upgradeTo(address newImplementation) public override onlyOwner onlyProxy {
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    // for receive native token
    receive() external payable {}

    /// @notice withdraw native token
    /// @param to the receiver address
    /// @param amount the amount to withdraw
    function withdrawNativeToken(address payable to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }

    /// @notice withdraw ERC20 token
    /// @param token the token address
    /// @param to the receiver address
    function withdrawToken(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    /// @notice set the current chain id
    /// @param chainId the current chain id
    function setSrcChainId(uint256 chainId) external onlyOwner {
        _currentChainId = chainId;
    }

    /// @notice set the trusted caller
    /// @param caller the caller address
    function addCaller(address caller) external onlyOwner {
        _callers[caller] = 1;
    }

    /// @notice remove the trusted caller
    /// @param caller the caller address
    function removeCaller(address caller) external onlyOwner {
        _callers[caller] = 0;
    }

    /// @notice add chain ids mapping to layerzero chain ids
    /// @param chainId the raw chain id
    /// @param lzChainId the layerzero chain id
    function addChainIdMapping(uint256 chainId, uint16 lzChainId) external onlyOwner {
        _chainIdMapping[chainId] = lzChainId;
        _lzChainIdMapping[lzChainId] = chainId;
    }

    /// @notice set the cross chain manager address
    /// deprecated no need to set cross chain manager address
    /// @param chainId the chain id
    /// @param crossChainManager the cross chain manager address
    function addCrossChainManagerMapping(uint256 chainId, address crossChainManager) external onlyOwner {
        _crossChainManagerMapping[chainId] = crossChainManager;
    }

    /// @notice set the cross chain relay address
    /// deprecated no need to set cross chain relay address
    /// @param chainId the chain id
    /// @param crossChainRelay the cross chain relay address
    function addCrossChainRelayMapping(uint256 chainId, address crossChainRelay) external onlyOwner {
        _crossChainRelayMapping[chainId] = crossChainRelay;
    }

    /// @notice set the manager address
    /// @param _address the manager address
    function setManagerAddress(address _address) external onlyOwner {
        _managerAddress = _address;
        _callers[_address] = 1;
    }

    /// @notice set the flow gas limit mapping
    /// @param flow the flow id
    /// @param gasLimit the gas limit
    function addFlowGasLimitMapping(uint8 flow, uint256 gasLimit) external onlyOwner {
        _flowGasLimitMapping[flow] = gasLimit;
    }

    /// @notice estimate gas fee for a center message
    /// @param data the cross chain meta message
    /// @param payload the payload
    /// @return the gas fee
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

    /// @notice send cross-chain message
    /// @param data the cross chain meta message
    /// @param payload the payload
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

    /// @notice send cross-chain message with fee
    /// @param data the cross chain meta message
    /// @param payload the payload
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

    /// @notice test function, send ping to another chain
    /// @param dstChainId the destination chain id
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

    /// @notice test function, send ping to another chain and expect pong back
    /// @param dstChainId the destination chain id
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

    /// @notice receive cross-chain message
    /// @param data the cross chain meta message
    /// @param payload the payload
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

    /// @notice receive cross-chain message from layzero endpoint
    /// @param _srcChainId the source chain id
    /// @param _payload the payload
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
