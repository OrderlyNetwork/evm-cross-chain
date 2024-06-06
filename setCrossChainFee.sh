ts-node foundry_ts/entry.ts --method setCrossChainFee --env dev --network opsepolia --ccmethod deposit --fee 300000 --multisig
ts-node foundry_ts/entry.ts --method setCrossChainFee --env dev --network arbsepolia --ccmethod deposit --fee 300000 --multisig
ts-node foundry_ts/entry.ts --method setCrossChainFee --env dev --network basesepolia --ccmethod deposit --fee 300000 --multisig
ts-node foundry_ts/entry.ts --method setCrossChainFee --env dev --network amoy --ccmethod deposit --fee 300000 --multisig
ts-node foundry_ts/entry.ts --method setCrossChainFee --env dev --network mantlesepolia --ccmethod deposit --fee 300000 --multisig
ts-node foundry_ts/entry.ts --method collectProposals --env dev --network arbsepolia --intent update_cross_chain_deposit_gas_limit --path ../safe-tasks/
ts-node foundry_ts/entry.ts --method collectProposals --env dev --network opsepolia --intent update_cross_chain_deposit_gas_limit --path ../safe-tasks/
ts-node foundry_ts/entry.ts --method collectProposals --env dev --network basesepolia --intent update_cross_chain_deposit_gas_limit --path ../safe-tasks/
ts-node foundry_ts/entry.ts --method collectProposals --env dev --network mantlesepolia --intent update_cross_chain_deposit_gas_limit --path ../safe-tasks/
ts-node foundry_ts/entry.ts --method collectProposals --env dev --network amoy --intent update_cross_chain_deposit_gas_limit --path ../safe-tasks/