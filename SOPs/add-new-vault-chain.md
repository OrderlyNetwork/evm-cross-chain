# Add New Vault Chain
to support new vault chain, you need to deploy the cross-chain contracts on the chain, and setup the contracts on the vault chain. The following steps will guide you through the process.

# SOP
**replace the values in `<>` with the actual values.**

1. Setup the new chain informations in `.env`

setup the following environment variables in `.env` file:
```shell
RPC_URL_<chain>=""
<chain>_CHAIN_ID=""
<chain>_EXPLORER_TYPE="" # blockscout or etherscan
<chain>_EXPLORER_API_URL=""
<chain>_ETHERSCAN_API_KEY=""
<chain>_LZ_CHAIN_ID=""
<chain>_ENDPOINT=""
```
2. Setup your private key in `.env` file
```shell
<chain>_PRIVATE_KEY=""
```
3. Setup USDC token information in `config/token-decimals.json`

add the following key-value pair under dev, qa, staging, or production keys.
```json
"<chain>": [
    {
        "name": "USDC",
        "tokenHash": "0xd6aca1be9729c13d677335161321649cccae6a591554772516700f986f942eaa",
        "decimals": 6
    }
]
```
4. Setup vault address in `config/project-related.json`

add the following key-value pair under dev, qa, staging, or production keys.
```json
"<chain>": {
    "vault": "<vault-address>"
}
```

5. Deploy the cross-chain contracts (vault cross-chain manager and cross-chain relay) on the new chain.

Run the following command to deploy the cross-chain contracts on the new chain:
```shell
ts-node foundry_ts/entry.ts --method addVaultCCService --env <env> --vaultNetwork <chain-name> --ledgerNetwork orderlyop --initEther 0.1 --broadcast --multisig --connectVault 
```

6. Prepare the multisig proposals to setup the contract on the ledger chain. 

Run the following command to prepare the multisig proposals:
```shell
ts-node foundry_ts/entry.ts --method collectProposals --env <env> --network orderlyop --intent <purpose-of-the-proposal> --path <path-to-safe-tasks>
```
this command will collect all txs under environment `env` and network `orderlyop` and save them as proposal json file to the path specified in `path`. you will receive output messages similar to the following:
```shell
 Sign proposal: <intent>
 execution network: orderlysepolia 
 env: <env>
  
 yarn safe propose-multi --network orderlysepolia --env dev <path-to-proposal-json-file> 
 yarn safe sign-proposal --network orderlysepolia <proposal-hash> 
 yarn safe submit-proposal --network orderlysepolia <proposal-hash>
```

7. Sign and submit the multisig proposals to setup the contract on the ledger chain.

Here is some different situations you may encounter:

7.1 If it is in staging and production, copy the above message(**the output messages**) and send to signers to sign the proposal. After collecting all signatures, merge the signatures and submit the proposal.
```shell
yarn safe merge --sig <path-to-signature> --network <network>
yarn safe submit-proposal --network <network> <proposal-hash>
```

7.2 If it is in dev and qa, sign and submit the proposal directly.
```shell
yarn safe sign-proposal --network orderlysepolia <proposal-hash> 
yarn safe submit-proposal --network orderlysepolia <proposal-hash>
```

8. Update the address information on confluence page.

Set the address of cross-chain-relay and vault-cross-chain-manager on the confluence page. https://wootraders.atlassian.net/wiki/spaces/ORDER/pages/359923713/MultiSig+Contract+for+Orderly+EVM

9. Verify the deployed contract on the chain.

if everything goes fine, the contract should be verified already. but if not, you can verify the contract on the chain by running the following command to get the standard json input file and submit it to broswer:
```shell
forge verify  <contract-address> <contract> --chain-id <chain-id> --show-standard-json-input > output.json
```

10. Sync the address of cross-chain-relay proxy to balance monitor

To maintain the service, we need to make sure the cross-chain-relay proxy address has enough balance to pay for the cross-chain fee. You need to sync the address of cross-chain-relay proxy to the balance monitor.