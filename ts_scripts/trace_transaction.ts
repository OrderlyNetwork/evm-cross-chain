import {ethers} from 'ethers';


async function getTrace(rpc: string, tx: string, from: string) {
    const provider = new ethers.JsonRpcProvider(rpc);
    const trace = await provider.send('trace_transaction', [tx]);
    console.log('trace: ', trace);
}

// run
const rpc = 'https://arb1.arbitrum.io/rpc'
const tx = '0xb1a67081bd847584dc7454da3713bbe3ecaccd34185401a12877e2083e47a893'
const from = '0x173B47eDBeCa665125edc24C509bfE545CDA60a9'

getTrace(rpc, tx, from);