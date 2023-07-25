import "./CrossChainRelay.sol";

contract CrossChainRelayMock is CrossChainRelay {
    constructor(address _endpoint, uint256 srcChainId, uint256 dstChainId, address relayTest) CrossChainRelay(_endpoint) {
       _currentChainId = srcChainId; 
       _callers[relayTest] = 1;
       _callers[_endpoint] = 1;
       _chainIdMapping[43113] = 10106;
       _chainIdMapping[80001] = 10109;
       _chainIdMapping[986532] = 10174;
       _lzChainIdMapping[10106] = 43113;
       _lzChainIdMapping[10109] = 80001;
       _lzChainIdMapping[10174] = 986532;
    }
}