// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interface/IOrderlyCrossChain.sol";
import "./utils/OrderlyCrossChainMessage.sol";
import "./layerzero/lzApp/LzAppUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrossChainRelayDataLayout {
    // A mapping to track trusted callers
    mapping(address => uint8) public _callers;

    // Raw chain id to layerzero chain id mapping
    mapping(uint256 => uint16) public _chainIdMapping;

    // layerzero chain id to raw chain id mapping
    mapping(uint16 => uint256) public _lzChainIdMapping;

    // chain id to cross chain manager contract address
    // @deprecated
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

    function initialize(address _endpoint) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __LzApp_init(_endpoint);
        _callers[msg.sender] = 1;
        _callers[_endpoint] = 1;
    }

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

    function withdrawNativeToken(address payable to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }

    function withdrawToken(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    // Set the Current Chain ID
    function setSrcChainId(uint256 chainId) external onlyOwner {
        _currentChainId = chainId;
    }

    // Allows the owner to add a trusted caller
    function addCaller(address caller) external onlyOwner {
        _callers[caller] = 1;
    }

    // Allows the owner to remove a trusted caller
    function removeCaller(address caller) external onlyOwner {
        _callers[caller] = 0;
    }

    // Allows the owner to add a chain id mapping
    function addChainIdMapping(uint256 chainId, uint16 lzChainId) external onlyOwner {
        _chainIdMapping[chainId] = lzChainId;
        _lzChainIdMapping[lzChainId] = chainId;
    }

    // Allows the owner to add a cross chain manager mapping
    function addCrossChainManagerMapping(uint256 chainId, address crossChainManager) external onlyOwner {
        _crossChainManagerMapping[chainId] = crossChainManager;
    }

    // Allows the owner to add a cross chain relay mapping
    function addCrossChainRelayMapping(uint256 chainId, address crossChainRelay) external onlyOwner {
        _crossChainRelayMapping[chainId] = crossChainRelay;
    }

    function setManagerAddress(address _address) external onlyOwner {
        _managerAddress = _address;
        _callers[_address] = 1;
    }

    // Allows the owner to add a flow gas limit mapping
    function addFlowGasLimitMapping(uint8 flow, uint256 gasLimit) external onlyOwner {
        _flowGasLimitMapping[flow] = gasLimit;
    }

    // estimate gas limit
    function estimateGasFee(OrderlyCrossChainMessage.MessageV1 memory data, bytes memory payload)
        public
        view
        override
        returns (uint256)
    {
        uint16 lzDstChainId = _chainIdMapping[data.dstChainId];
        require(lzDstChainId != 0, "CrossChainRelay: invalid dst chain id");
        uint16 version = 1;
        uint256 gasLimit = _flowGasLimitMapping[data.method];
        if (gasLimit == 0) {
            gasLimit = 3000000;
        }
        bytes memory adapterParams = abi.encodePacked(version, gasLimit);
        (uint256 nativeFee,) = lzEndpoint.estimateFees(lzDstChainId, address(this), payload, false, adapterParams);
        return nativeFee;
    }

    // Allows a trusted caller to send a message
    function sendMessage(OrderlyCrossChainMessage.MessageV1 memory data, bytes memory payload)
        public
        payable
        override
    {
        require(_callers[msg.sender] == 1, "Caller is not the trusted caller");
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

    function ping(uint256 dstChainId) public {
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

    // Allows a trusted caller to receive a message
    function receiveMessage(OrderlyCrossChainMessage.MessageV1 memory data, bytes memory payload)
        public
        payable
        override
    {
        require(_callers[msg.sender] == 1, "Caller is not the trusted caller");
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

    //function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload)
    function _blockingLzReceive(uint16 _srcChainId, bytes memory, uint64, bytes memory _payload)
        internal
        virtual
        override
    {
        uint256 rawSrcChainId = _lzChainIdMapping[_srcChainId];
        require(rawSrcChainId != 0, "CrossChainRelay: invalid src chain id");
        (OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload) =
            OrderlyCrossChainMessage.decodeMessageV1AndPayload(_payload);
        //require(message.srcChainId == rawSrcChainId, "CrossChainRelay: invalid src chain id");
        //require(_crossChainRelayMapping[rawSrcChainId] == address(bytes20(_srcAddress)), "CrossChainRelay: invalid src address");
        emit MsgReceived(message.method);

        receiveMessage(message, payload);
    }
}
