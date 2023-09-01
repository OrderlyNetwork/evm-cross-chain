# Orderly Cross-Chain Service
## Introduction
This project is built for providing cross-chain service for Orderly V2, which has components including multiple vaults, a dedicated ledger, cross-chain managers for both the vaults and the ledger, and cross-relay for each chain with our services. These components are deployed across blockchains, such as Ethereum, Arbitrum, and Avalanche. The vaults serve as secure repositories for user funds, while the ledger acts as a comprehensive database for all user-related information. To facilitate seamless communication between the vaults and the ledger—each residing on different blockchains—we have implemented dedicated cross-chain managers. These managers are tasked with converting messages into cross-chain payloads, enabling fluid inter-blockchain communication. Recognizing the variety of existing cross-chain solutions, a relay is positioned on each blockchain to encapsulate multiple cross-chain options. This relay plays a key role in transmitting messages from the cross-chain managers, thereby ensuring robust and flexible cross-chain interactions

## Diagram
![structure](imgs/infra)

## An simple example: deposit

1. The vault receives a user's deposit request.

2. The deposit message is sent to the Vault Cross-Chain Manager.

3. The manager constructs a cross-chain message including source and target chain information.

4. This message is sent to the Relay on the source chain.

5. The Relay transmits the message to the target chain, where the Ledger is deployed.

6. The Relay on the target chain forwards the message to the Ledger Cross-Chain Manager.

7. This manager decodes the message and constructs a recognizable message for the Ledger.

8. Finally, the Ledger processes the deposit.

## File Structure

Here's an overview of the main folders in this project and what they contain:

* `contracts/`: This folder houses all the Solidity smart contracts essential for the project's blockchain functionality.

* `baseScripts/`: Contains the base classes for various scripts along with utility functions and helpers.

* `easyScripts/`: This directory is specifically designed for Foundry scripts that facilitate deployment, setup, and other operational tasks.

* `config/tasks/`: Holds JSON files that configure and parameterize the scripts, making it easier to manage tasks.

* `config/`: A general folder for storing project-related informations like contract address.

## Deployment and Setup

#### Setup RPCs and Related infos in .env

1. Setup available accounts(format like this: `ORDERLY_PRIVATE_KEY`, network name with `_PRIVATE_KEY`)

2. Setup RPC URLs

3. Setup Endpoins addresses

4. And some configuration file paths for scripts

you can refer to `.env.example`. I am using foundry for deployment and scripting. My scripts will read infos from `.env` and r/w json files under `config`. 
### Deployment

1. **Cross-Chain Relay Deployment**

for cross-chain relay's deployment, you need to write a json file for the task and put it under `config/tasks`.
And then set `DEPLOY_RELAY_CONFIG_FILE` to the path of the json file in `.env`.
The format of the json file look like this:
```json
{
    "networks": [
        "orderlyop",
        "arbitrumgoerli"
    ],
    "env": "staging"
}
```
in this json, it specifies the networks on which the relay should be deployed. and set the environment is staging.
the you can run to deploy cross-relay on both orderlyop and arbitrumgoerli:
```shell
forge script easyScripts/deployRelay.s.sol -vvvv --broadcast
```
one more thing, you should add the following json into `cross-chain-relay.json` under `config`:
```json
  "staging": {
    "orderlyop": {
      "owner": "",
      "proxy": "",
      "relay": ""
    },
    "arbitrumgoerli": {
      "owner": "",
      "proxy": "",
      "relay": ""
    }
  }
```
the reason is because foundry script will not write the key if it is not in the json file. So, we manual setup the keys in the json file. After deployment, you will have a updated json file will information about your deployment.

2. **Cross-Chain Manager Deployment** 

the following steps are similiar, you can refer to example task json files under `config/tasks`.

a. write a task json and set the env var `DEPLOY_CCMANAGER_CONFIG_FILE` in `.env`

b. add required keys in json file `cross-chain-manager.json`

c. run `forge script easyScripts/deployCCManager.s.sol -vvvv --broadcast`

3. **Cross-Chain Relay Setup**

a. write a task json and set env var `SETUP_RELAY_CONFIG_FILE` in `.env`

b. run `forge script easyScripts/setupRelay.s.sol -vvvv --broadcast`

4. **Cross-Chain Manager Setup**

a. write a task json and set env var `SETUP_CCMANAGER_CONFIG_FILE` in `.env`

b. run `forge script easyScripts/setupCCManager.s.sol -vvvv --broadcast`

5. **Set Manager Address in Relays**

a. write a task json and set env var `SET_CCMANAGER_CONFIG_FILE` in `.env`

b. run `forge script easyScripts/setManager.s.sol  -vvvv --broadcast`

after the finish the above steps, we have our cross-chain managers and relays deployed. The reason that we don't write a single script to do it is because of the limitation of foundry scripts. And also because some operations can be run repeatedly such as setup. We can also use shell scripts to turn the above steps into one single script.

## More on standard of scripting
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


## License
[MIT License](LICENSE)