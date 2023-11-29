pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../contracts/CrossChainRelayUpgradeable.sol";
import "../contracts/CrossChainRelayProxy.sol";
import "../contracts/layerzero/mocks/LZEndpointMock.sol";

contract CrossChainRelaySetup is Test {
    uint16 constant _vaultLzChainId = 1001;
    uint16 constant _ledgerLzChainId = 1002;
    uint16 constant _vaultChainId = 1;
    uint16 constant _ledgerChainId = 2;
    CrossChainRelayProxy _srcRelayProxy;
    CrossChainRelayProxy _dstRelayProxy;
    CrossChainRelayUpgradeable _srcRelayImpl;
    CrossChainRelayUpgradeable _dstRelayImpl;
    LZEndpointMock _srcEndpoint;
    LZEndpointMock _dstEndpoint;

    function deployCrossChainRelay() public {
        _srcEndpoint = new LZEndpointMock(_vaultLzChainId);
        _dstEndpoint = new LZEndpointMock(_ledgerLzChainId);
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

        srcRelay.setTrustedRemote(_ledgerLzChainId, srcToDstPath);
        dstRelay.setTrustedRemote(_vaultLzChainId, dstToSrcPath);

        srcRelay.setSrcChainId(_vaultChainId);
        srcRelay.addChainIdMapping(_vaultChainId, _vaultLzChainId);
        srcRelay.addChainIdMapping(_ledgerChainId, _ledgerLzChainId);

        dstRelay.setSrcChainId(_ledgerChainId);
        dstRelay.addChainIdMapping(_vaultChainId, _vaultLzChainId);
        dstRelay.addChainIdMapping(_ledgerChainId, _ledgerLzChainId);
    }

    function newCrossChainRelay() public returns (CrossChainRelayProxy) {
        CrossChainRelayProxy proxy = new CrossChainRelayProxy(address(new CrossChainRelayUpgradeable()), bytes(""));
        CrossChainRelayUpgradeable(payable(address(proxy))).initialize(address(_srcEndpoint));
        return proxy;
    }
}
