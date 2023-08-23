import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
// use dotenv
import dotenv from "dotenv";
dotenv.config();
import fs from "fs";

// {
//   "network_pairs": [
//       {
//           "network_1": {
//               "name": "orderly",
//               "relayAddress": "",
//               "chainId": 1,
//               "rpc": ""
//           },
//           "network_2": {
//               "name": "fuji",
//               "relayAddress": "",
//               "chainId": 2,
//               "rpc": ""
//           }
//       }
//   ]
// }

interface NetworkInfo {
  name: string;
  relayAddress: string;
  chainId: number;
  rpc: string;
}
interface NetworkPair {
  network_1: NetworkInfo;
  network_2: NetworkInfo;
}

interface NetworkPairs {
  network_pairs: NetworkPair[];
}

interface CrossChainProcessInfo {
  finishedBlock: number;
  finishedIndex: number;
}

interface CrossChainMessage {
  method: number;
  option: number;
  payloadDataType: number;
  srcCrossChainManager: string;
  dstCrossChainManager: string;
  srcChainId: number;
  dstChainId: number;
}

const eventSignature = 'MessageSent((uint8,uint8,uint8,address,address,uint256,uint256),bytes)'
//const eventSignature = 'MessageSent(OrderlyCrossChainMessage.MessageV1,bytes)'

async function sendMsg(networkInfo: NetworkInfo, data: string, hre: HardhatRuntimeEnvironment) {
  const { name, relayAddress, chainId, rpc } = networkInfo;

  // ethers decode abi
  const decodedData = hre.ethers.AbiCoder.defaultAbiCoder().decode(
    [ 'uint8', 'uint8', 'uint8', 'address', 'address', 'uint256', 'uint256', 'bytes'],
    data
  );

  console.log('functionData: ', decodedData);
  const crossChainMessage: CrossChainMessage = {
    method: decodedData[0],
    option: decodedData[1],
    payloadDataType: decodedData[2],
    srcCrossChainManager: decodedData[3],
    dstCrossChainManager: decodedData[4],
    srcChainId: decodedData[5],
    dstChainId: decodedData[6],
  };
  console.log('crossChainMessage: ', crossChainMessage);
  // dstChainId must equal to networkChainId
  if (crossChainMessage.dstChainId !== chainId) {
    console.log(`crossChainMessage.dstChainId ${crossChainMessage.dstChainId} not equal to networkChainId ${chainId}, skip`);
    return;
  }
  
  // set provider
  const provider = new hre.ethers.JsonRpcProvider(rpc);
  // get pk and set an account 
  const pk = process.env[`${name.toUpperCase()}_PRIVATE_KEY`];
  if (pk === undefined) {
    throw new Error(`private key not found for network ${name}`);
  }
  const wallet = new hre.ethers.Wallet(pk, provider);

  const relayContract = await hre.ethers.getContractAt('CrossChainRelayUpgradeable', relayAddress);
  
  let tx;
  while (true) {
    try {
      tx = await relayContract.connect(wallet).receiveMessage(crossChainMessage, decodedData[7]);
      break;
    } catch (e) {
      console.log(`tx failed or reverted, wait for 5 seconds and retry`);
      await new Promise(r => setTimeout(r, 5000));
    }
  }

  // wait for tx
  tx.wait();
  
  console.log('tx hash: ', tx.hash);
  
}

async function getLatestBlock(networkPair: NetworkPair, hre: HardhatRuntimeEnvironment) {

    const network1 = networkPair.network_1;
    const network2 = networkPair.network_2;
    const { name, relayAddress, chainId, rpc } = network1;

    // get event topics
    const eventTopic = hre.ethers.id(eventSignature);
    console.log(`event topic: `, eventTopic)

    // create provider
    const provider = new hre.ethers.JsonRpcProvider(rpc);

    // get all files match the pattern
    const sentFiles = fs.readdirSync('mockSentMsgs').filter(fn => fn.startsWith(`${name}-`));
    console.log(`files: `, sentFiles)

    // load finished-block from json
    // file name network-finished-block.json
    const fileName = `mockToSendMsgs/${name}-${network2.name}-finished-block.json`;
    // load file
    const file = fs.readFileSync(fileName);
    // parse file
    const crossChainProcessInfo: CrossChainProcessInfo = JSON.parse(file.toString());
    console.log(`crossChainProcessInfo: `, crossChainProcessInfo)
    if (crossChainProcessInfo.finishedBlock === undefined) {
      console.log(`crossChainProcessInfo.finishedBlock is undefined`)
      return;
    }
    // forever loop
    // get block when block number > finished-block
    // save to file
    // update finished-block
    // else sleep 1 second
    while (true) {
      const blockNumber = await provider.getBlockNumber();
      if (crossChainProcessInfo.finishedBlock < blockNumber) {

        const logs = await provider.getLogs({
          fromBlock: crossChainProcessInfo.finishedBlock,
          toBlock: crossChainProcessInfo.finishedBlock,
        });

        // and filter logs by event topic and contract address (relayAddress)
        const myEvents = logs.filter((log) => {
          return log.topics.includes(eventTopic) && log.address === relayAddress && log.index > crossChainProcessInfo.finishedIndex;
        });

        // sort myEvents by blockNumber and index
        myEvents.sort((a, b) => {
          if (a.blockNumber === b.blockNumber) {
            return a.index - b.index;
          } else {
            return a.blockNumber - b.blockNumber;
          }
        });
        console.log(`myEvents: `, myEvents)
        
        // process all events
        for (let i = 0; i < myEvents.length; i++) {
          const log = myEvents[i];
          await sendMsg(network2, log.data, hre);
          // update 
          crossChainProcessInfo.finishedIndex = log.index;
          fs.writeFileSync(fileName, JSON.stringify(crossChainProcessInfo, null, 2));
        }

        crossChainProcessInfo.finishedBlock += 1;
        crossChainProcessInfo.finishedIndex = -1;
        // write back to file
        fs.writeFileSync(fileName, JSON.stringify(crossChainProcessInfo, null, 2));

      } else {
        await new Promise(r => setTimeout(r, 10));
      }
    }


  }


task("mockCrossChain",
  "mock cross-chain message passing",
  async (taskArgs: any, hre: HardhatRuntimeEnvironment) => {
    // print ethers version
    console.log('ethers version: ', hre.ethers.version);

    // load network pairs from file
    const configPath = 'mockToSendMsgs/config.json';
    const file = fs.readFileSync(configPath);
    // load from file
    const networkPairs: NetworkPairs = JSON.parse(file.toString());
    // run all all pairs in different threads simultaneously
    // await Promise.all([
    //   getLatestBlock(network1, network2, hre),
    //   getLatestBlock(network2, network1, hre),
    // ]);
    const promises = networkPairs.network_pairs.map(networkPair => getLatestBlock(networkPair, hre));
    Promise.all(promises).then(() => {
      console.log('all done');
    }).catch((e) => {
      console.log('error: ', e);
    });

    // loop forever
    while (true) {
      await new Promise(r => setTimeout(r, 10000));
    }

})
  

// command of calling this task
// npx hardhat mockCrossChain --src-network orderly --dst-network fuji