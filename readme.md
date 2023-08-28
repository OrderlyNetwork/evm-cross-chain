# Cross-Chain Relay

# Get Started
1. Setup available accounts
2. Setup RPC URLs
3. Setup Endpoins addresses
# Scripts introduction
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


## How to run scripts
here is a scripts for substituting env variables in `.env` so that we can pass config file as arguments.
just run
```shell
bash easyScripts/easy_script.sh setup config/tasks/qa-setupRelay.json
```
the env variable associated with setup command will be replace with the new value. then you can run foundry scripts like this:
```shell
easyScripts/setupRelay.s.sol -vvvv --broadcast
```
you don't need to pass the rpc url, because the scripts will do it base on your config.