import {ethers, Log} from 'ethers';
import {createClient} from '@layerzerolabs/scan-client';
// dotenv 
import dotenv from 'dotenv';
dotenv.config();

interface GasConsumption {
    gasUsed: bigint,
    gasPrice: bigint,
    gasCost: bigint,
    tokenTransfer:bigint 
}
const rpc = process.env.RPC_URL_ORDERLYMAIN;
if (!rpc) throw new Error('RPC_URL_ORDERLYMAIN is not defined in .env file');
const provider = new ethers.JsonRpcProvider(rpc);
const client = createClient('mainnet');

async function getInternalTxs(contractAddress: string, topics: Array<string>) : Promise<Array<Log>>  {
    // get all transactions asscoiated with the contract address
    const logs = await provider.getLogs({address: contractAddress, topics, fromBlock: 0, toBlock: 'latest',});
    return logs;
}

async function analyzeTx(txHash: string) : Promise<GasConsumption> {
    const tx = await provider.getTransactionReceipt(txHash);
    if (!tx) throw new Error(`tx ${txHash} not found`);
    const txResult = provider.getTransactionResult(txHash);
    console.log(txResult);
    console.log('tx: ', tx);
    return {
        gasUsed: tx.gasUsed,
        gasPrice: tx.gasPrice,
        gasCost: tx.gasUsed * tx.gasPrice,
        tokenTransfer: BigInt(0)
    };
}


async function main() {
    const contractAddress = '0x7CC5B6433eb33164c88F6512f56C566CFC3420BF'
    const topics = ['0x95ad3b8e2ef90266b08e31ec4f1058ad175217f2f7a1565a383da6f9c9d8a5ac']
    const logs = await getInternalTxs(contractAddress, topics);
    // console.log('logs: ', logs);
    for (const log of logs) {
        const gasConsumption = await analyzeTx(log.transactionHash);
        console.log('gasConsumption: ', gasConsumption);
    }
}

Promise.resolve(main())
    .then(() => {
        process.exit(0);
    })
    .catch(error => {
        console.error(error);
        process.exit(1);
    });