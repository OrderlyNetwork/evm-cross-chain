pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainRelayProxy.sol";
import "../contracts/layerzero/mocks/LZEndpointMock.sol";

contract CrossChainRelaySetup is Test {
    uint16 constant _srcLzChainId = 1001;
    uint16 constant _dstLzChainId = 1002;
    uint16 constant _srcChainId = 1;
    uint16 constant _dstChainId = 2;
    CrossChainRelayProxy _srcRelayProxy;
    CrossChainRelayProxy _dstRelayProxy;
    CrossChainRelayUpgradeable _srcRelayImpl;
    CrossChainRelayUpgradeable _dstRelayImpl;
    LZEndpointMock _srcEndpoint;
    LZEndpointMock _dstEndpoint;

    function deployCrossChainRelay() public {
        _srcEndpoint = new LZEndpointMock(_srcLzChainId);
        _dstEndpoint = new LZEndpointMock(_dstLzChainId);
        _srcRelayProxy = new CrossChainRelayProxy(address(new CrossChainRelayUpgradeable()), bytes(""));
        _dstRelayProxy = new CrossChainRelayProxy(address(new CrossChainRelayUpgradeable()), bytes(""));

        CrossChainRelayUpgradeable(payable(address(_srcRelayProxy))).initialize(address(_srcEndpoint));
        CrossChainRelayUpgradeable(payable(address(_dstRelayProxy))).initialize(address(_dstEndpoint));
    }

    function setupCrossChainRelay() public {
        _srcEndpoint.setDestLzEndpoint(address(_dstRelayProxy), address(_dstEndpoint));
        _dstEndpoint.setDestLzEndpoint(address(_srcRelayProxy), address(_srcEndpoint));

        bytes memory srcToDstPath = abi.encodePacked(_dstRelayProxy, _srcRelayProxy);
        bytes memory dstToSrcPath = abi.encodePacked(_srcRelayProxy, _dstRelayProxy);

        CrossChainRelayUpgradeable srcRelay = CrossChainRelayUpgradeable(payable(address(_srcRelayProxy)));
        CrossChainRelayUpgradeable dstRelay = CrossChainRelayUpgradeable(payable(address(_dstRelayProxy)));

        srcRelay.setTrustedRemote(_dstLzChainId, srcToDstPath);
        dstRelay.setTrustedRemote(_srcLzChainId, dstToSrcPath);

        srcRelay.setSrcChainId(_srcChainId);
        srcRelay.addChainIdMapping(_srcChainId, _srcLzChainId);
        srcRelay.addChainIdMapping(_dstChainId, _dstLzChainId);

        dstRelay.setSrcChainId(_dstChainId);
        dstRelay.addChainIdMapping(_srcChainId, _srcLzChainId);
        dstRelay.addChainIdMapping(_dstChainId, _dstLzChainId);
    }

    function newCrossChainRelay() public returns (CrossChainRelayProxy) {
        CrossChainRelayProxy proxy = new CrossChainRelayProxy(address(new CrossChainRelayUpgradeable()), bytes(""));
        CrossChainRelayUpgradeable(payable(address(proxy))).initialize(address(_srcEndpoint));
        return proxy;
    }
}
