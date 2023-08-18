import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
// use dotenv
import dotenv from "dotenv";
dotenv.config();

interface CrossChainProcessInfo {
  currentBlock: number;
}

const eventSignature = 'MessageSent((uint8,uint8,uint8,address,address,uint256,uint256),bytes)'
//const eventSignature = 'MessageSent(OrderlyCrossChainMessage.MessageV1,bytes)'

async function getLatestBlock(network: string, hre: HardhatRuntimeEnvironment) {
    const { ethers } = hre;
    // convert network name to RPC URL env var name, put in uppercase
    const rpcUrlEnvVarName = `RPC_URL_${network.toUpperCase()}`;
    // from dotenv get network provider, e.g. "RINKEBY_RPC_URL"
    const netowrkRpcUrl = process.env[rpcUrlEnvVarName];
    console.log(`network ${network} RPC URL: `, netowrkRpcUrl)

    // get event topics
    const eventTopic = hre.ethers.id(eventSignature);
    console.log(`event topic: `, eventTopic)

    // create provider
    const provider = new hre.ethers.JsonRpcProvider(netowrkRpcUrl);
    const blockNumber = await provider.getBlockNumber();
    const block = await provider.getBlock(blockNumber);
    const logs = await provider.getLogs({
      fromBlock: 23783476,
      toBlock: 23783476,
    });

    const myEvents = logs.filter((log) => log.topics[0] === eventTopic);
    // decode event data log.data according to MessageSent event ABI
    const decodedEvents = myEvents.map((log) => {
      const iface = new ethers.Interface(['event MessageSent(uint8, uint8, uint8, address, address, uint256, uint256, bytes)']);
      iface.getAbiCoder();
      const decodedLog = iface.decodeEventLog('MessageSent', log.data);
      return decodedLog;
    });
    console.log(`decoded events: `, decodedEvents)

    // print network and its latest block
    console.log(`${network} latest block: `, block)
    console.log(`${network} latest block number: `, blockNumber)
    console.log(`${network} latest block logs: `, myEvents)
  }


task("mockCrossChain",
  "mock cross-chain message passing",
  async (taskArgs: any, hre: HardhatRuntimeEnvironment) => {
    // print ethers version
    console.log('ethers version: ', hre.ethers.version);
    // get src network and dst network from taskArgs
    const { srcNetwork, dstNetwork } = taskArgs;

    await getLatestBlock(dstNetwork, hre);
    await getLatestBlock(srcNetwork, hre);
}).addParam("srcNetwork", "The cross-chain source network")
  .addParam("dstNetwork", "The cross-chain destination network")

// command of calling this task
// npx hardhat mockCrossChain --src-network orderly --dst-network fuji