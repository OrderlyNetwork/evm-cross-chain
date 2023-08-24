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
first you need set the endpoint address in `.env`. and you should set the relay proxy address and also `CURRENT_NETWORK` in `.env`. and then call the command:
```shell
forge script forgeScripts/updateEndpoint.s.sol --rpc-url $RPC_URL_XXX -vvvv  --via-ir --broadcast
```

# All Forge Script Deployment and Confiuration
Consider using all forge scripts to deploy, upgrade, setup, update and more operations. Because forge scripts also support read and write files.

Operations are all configured in files under `config/tasks`, project related variables are put under `config`, for example `cross-chain-relay.json` stores the latest cross-chain-relay and its proxy address.
## Deployment

```shell
forge script easyScripts/deployRelay.s.sol  -vvvv  --via-ir --broadcast
```


# New scripts introduction
## env variables
there are three types of envs:
1. public envs: RPC_URLs, Private Keys, Chain IDs, etc. Something that not change very often
2. project related envs: contract deployment address, or other information
3. script configuration files

for type 1, it should be stored in `.env`, for type 2, it should be automatically stored in json, and it can be easily copy to other projects. for type 3, it should also stored in json files.

But there is a problem, foundry script doesn't accept custom arguments, so we have to put argument into `.env`. here is some example:
```bash
### deploy relay
DEPLOY_RELAY_CONFIG_FILE="config/tasks/qa-deploy.json"
### setup relay
SETUP_RELAY_CONFIG_FILE="config/tasks/qa-deploy.json"
### set manager
SET_CCMANAGER_CONFIG_FILE="config/tasks/setManager.json"


## project relate env files
DEPLOY_RELAY_SAVE_FILE="config/cross-chain-relay.json"
DEPLOY_MANAGER_SAVE_FILE="config/cross-chain-manager.json"
```
for every command like deploy, setup, or others, there should be a env varibale in `.env`. for project related variable it also needs an env variables.

## json format
### type 2
first classify using environment, qa, dev, release, etc. then network names like this:
```json
{
  "qa-mock": {
    "fuji": {
      "owner": "0xF6e22738295Af46e8B0dd35F7426f0f83aD0ff6C",
      "proxy": "0xBE404b97de8A6B1304F3dbC17F565034721A40b7",
      "relay": "0xAcf376844CEDe2f8cdaA8bA88A44FE4d4332A4DF"
    },
    "orderly": {
      "owner": "0xF6e22738295Af46e8B0dd35F7426f0f83aD0ff6C",
      "proxy": "0x8E1f5dBF1E0601f99bE7563cca3B319AdF814684",
      "relay": "0xB20a5257B32bFb0E17C10Ed98CD618335bBA0EFF"
    }
  }
}
```
### type 3
for this type, you can define by your own.

## foundry script
for every foundry script, you should have a config json, you define your struct inside your script. and you should automatically save your deployment and neccessary information into corresponding json files. please refer to `easyScripts/deployRelay.s.sol`

all base script contracts and helper function are under `baseScripts`