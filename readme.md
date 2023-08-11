# Cross-Chain Relay

# Get Started
1. Setup available accounts
2. Setup RPC URLs
3. Setup Endpoins addresses

# Operations
## Deploy Proxy and Upgradeable Relay
```shell
yarn run hardhat --network orderly run scripts/deployRelayUpgradeable.ts  
yarn run hardhat --network fuji run scripts/deployRelayUpgradeable.ts  
```
## Setup Relay
1. setup chain ID mapping from native chain ID to Layerzero chain ID
2. set current chain ID
3. set trusted remote for layerzero
4. transfer native tokens to contract
```shell
yarn run hardhat --network orderly setupRelay --target-network fuji
yarn run hardhat --network fuji setupRelay --target-network orderly
```
## Upgrade Proxy
```shell
yarn run hardhat --network orderly run scripts/upgradeRelay.ts 
yarn run hardhat --network fuji run scripts/upgradeRelay.ts 
```
## Ping Pong Test Cross-Chain Messages
```shell
yarn run hardhat --network orderly sendPing --target-network fuji 
yarn run hardhat --network fuji sendPing --target-network orderly
```
## Retry LZ Paylaod
setup variables in `.env`:
```yml
# parameters for foundry scripts
CURRENT_NETWORK="fuji"
RETRY_PAYLOAD_RAW_DATA="0x"
```
```shell
source .env
forge script forgeScripts/RelayRetry.s.sol  --rpc-url $RPC_URL_ORDERLY -vvvv  --via-ir
```

## Withdraw from relay
set `WITHDRAW_RELAY_ADDRESS` and `CURRENT_NETWORK` in `.env`, and run:
```shell
source .env
forge script forgeScripts/RelayWithdraw.s.sol  --rpc-url $RPC_URL_FUJI -vvvv  --via-ir --broadcast
```

## Transfer To Relay
set `TRANFER_ADDRESS`, `TRANSFER_AMOUNT` and `CURRENT_NETWORK` in `.env`, and run:
```shell
source .env
forge script forgeScripts/Transfer.s.sol  --rpc-url $RPC_URL_FUJI -vvvv  --via-ir --broadcast
```
