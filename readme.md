# Cross-Chain Relay

# Get Started
1. Setup available accounts
2. Setup RPC URLs
3. Setup Endpoins addresses

# Operations

## Workflow
1. you need to set all common public env variables first
 - RPC urls for each network in `.env` and `hardhat.config.ts`
 - chain ids for each network in `.env` and `hardhat.config.ts`
 - private keys for each network `.env`
 - lz endpoints address in `.env` `constants/lzEndpoints.ts` and `constants/layerzeroEndpoints.json`
 - lz chain ids and mappings in `constants/chainIds.ts` and `constants/lzChainIdMapping.ts`
2. set project related env variables
 *after deployment:*
 - vault relay address per network
 - ledger relay address per network
 *after setup:*
 - ledger manager address
 - vault manager address
2. deploy relay
3. setup relay
4. send test tx(ABA) for test cross-chain msg sending and receiving
5. set manager address
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
CURRENT_NETWORK="fuji" # or other network name
RETRY_PAYLOAD_RAW_DATA="0x"
```
```shell
source .env
forge script forgeScripts/RelayRetry.s.sol  --rpc-url $RPC_URL_XXX -vvvv  --via-ir
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

## Check Payload Stored
visit https://testnet.layerzeroscan.com/ to search to the initial tx hash, then you can see the payload status.

## Add New Caller
you need to set `CURRENT_NETWORK` `NEW_CALLER` in `.env`. and then call:
```shell
forge script forgeScripts/RelayAddCaller.sol  --rpc-url $RPC_URL_XXX -vvvv  --via-ir --broadcast
```
replace XXX with the network name that suits you.

## Set Manager address and add as caller
you need to set `CURRENT_NETWORK` in `.env` and then call:
```shell
forge script forgeScripts/SetManagerAddress.sol --rpc-url $RPC_URL_XXX -vvvv  --via-ir --broadcast
```
replace XXX with the network name that suits you.

## Update Layerzero Endpoint
first you need set the endpoint address in `.env`. and you should set the relay proxy address in `.env`. and then call the command:
```shell
