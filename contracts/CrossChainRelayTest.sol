
import "../contracts/interface/IOrderlyCrossChain.sol";

contract CrossChainRelayTest is IOrderlyCrossChainReceiver {

    event MessageReceived(
        OrderlyCrossChainMessage.MessageV1 indexed message,
        OrderlyCrossChainMessage.MessageV1 indexed decodedMessage
    );

    IOrderlyCrossChain public _crossChainRelay;

    function setCrossChainRelay(address crossChainRelay) external {
        _crossChainRelay = IOrderlyCrossChain(crossChainRelay);
    }

    function receiveMessage(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload) external override {

        OrderlyCrossChainMessage.MessageV1 memory decodedMessage = abi.decode(payload, (OrderlyCrossChainMessage.MessageV1));
        emit MessageReceived(message, decodedMessage);
        if (message.method == 1) {
            message.method = 0;
            uint256 dstChainId = message.srcChainId;
            message.srcChainId = message.dstChainId;
            message.dstChainId = dstChainId;
            address dstCrossChainManager = message.srcCrossChainManager;
            message.srcCrossChainManager = message.dstCrossChainManager;
            message.dstCrossChainManager = dstCrossChainManager;
            _crossChainRelay.sendMessage(message, payload);
        }
    }

    function sendSampleMessage(uint8 method, address dstContract, uint256 srcChainId, uint256 dstChainId) external payable {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: method,
            option: 2,
            payloadDataType: 3,
            srcCrossChainManager: address(this),
            dstCrossChainManager: dstContract,
            srcChainId: srcChainId,
            dstChainId: dstChainId
        });
        bytes memory payload = abi.encode(message);
        _crossChainRelay.sendMessage(message, payload);
    }
}