// SPX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// project dependencies
import "../interface/ICrossChainAdapter.sol";
import "../interface/IOrderlyCrossChain.sol";

/// openzeppelin dependencies
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// axelar dependencies
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IAxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarExecutable.sol';

contract AxelarCCAdapterData {
    /// Axelar related configurations
    IAxelarGasService public gasService;
    IAxelarGateway public gatewayContract;
    mapping(uint256 => string) public chainId2Name;
    mapping(uint256 => string) public chainId2Address;

    /// orderly project configurations
    IOrderlyCrossChain public crossChainRelay;

    /// @dev gap for future storage
    uint256[50] private __gap;
}


contract AxelarCCAdapter is ICrossChainAdapter, IAxelarExecutable, Initializable, OwnableUpgradeable, UUPSUpgradeable, AxelarCCAdapterData {

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }


    /// @dev only owner can upgrade
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner{}

    /// @dev estimate gas for sending a cross chain message
    function estimateGas(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload) external view override returns (uint256) {
        return 0;
    }

    /// @dev set axelar configurations
    /// @param _gasService gas service address
    /// @param _gateway gateway address
    function setAxelarConfig(address _gasService, address _gateway) external onlyOwner {
        gasService = IAxelarGasService(_gasService);
        gatewayContract = IAxelarGateway(_gateway);
    }

    /// @dev set the Axelar related chain id, chain name, and chain address
    /// @param chainId native chain id of the chain
    /// @param name axelar chain name
    /// @param dstAddress the deployed axelar executor contract address
    function setChainId2Name(uint256 chainId, string memory name, string memory dstAddress) external onlyOwner {
        chainId2Name[chainId] = name;
        chainId2Address[chainId] = dstAddress;
    }

    /// @dev return the gateway contract address
    /// @return IAxelarGateway the gateway contract
    function gateway() external view override returns (IAxelarGateway) {
        return gatewayContract;
    }

    /*** START ** Axelar Sender Functions ** START ***/

    /// @dev send a cross chain message
    function send(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory orderlyPayload) external payable override {
        
        string memory destinationChain = chainId2Name[message.dstChainId];
        string memory destinationAddress = chainId2Address[message.dstChainId];

        bytes memory payload = OrderlyCrossChainMessage.encodeMessageV1AndPayload(message, orderlyPayload);

        axelarSend(destinationChain, destinationAddress, payload);

        emit OrderlyCCMessageSent(message, payload);
    }

    function axelarSend(
        string memory destinationChain,
        string memory destinationAddress,
        bytes memory payload
    ) internal {
        gasService.payNativeGasForContractCall{value: msg.value} (
            address(this),
            destinationChain,
            destinationAddress,
            payload,
            msg.sender
        );

        gatewayContract.callContract(destinationChain,destinationAddress,payload);
    }

    /*** END ** Axelar Sender Functions ** END ***/

    /*** START ** Axelar Receiver Functions ** START ***/
    
    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        bytes32 payloadHash = keccak256(payload);

        if (!gatewayContract.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash))
            revert NotApprovedByGateway();

        _execute(sourceChain, sourceAddress, payload);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external {
        bytes32 payloadHash = keccak256(payload);

        if (
            !gatewayContract.validateContractCallAndMint(
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash,
                tokenSymbol,
                amount
            )
        ) revert NotApprovedByGateway();

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    function _execute(
        string calldata,
        string calldata,
        bytes calldata payload
    ) internal {
        // decode the payload
        (OrderlyCrossChainMessage.MessageV1 memory message, bytes memory orderlyPayload) = abi.decode(payload, (OrderlyCrossChainMessage.MessageV1, bytes));

        // emit 
        emit OrderlyCCMessageReceived(message, orderlyPayload);

        // send the message to orderly
        crossChainRelay.receiveMessage(message, payload);
    }

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal {
        /// @dev not implemented yet, revert
        revert("not implemented yet");
    }

    /*** END ** Axelar Receiver Functions ** END ***/

}