import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
// use dotenv
import dotenv from "dotenv";
dotenv.config();
import fs from "fs";

interface CrossChainProcessInfo {
  finishedBlock: number;
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

async function sendMsg(network: string, data: string, relayAddress: string, hre: HardhatRuntimeEnvironment) {

  const networkChainId = process.env[`${network.toUpperCase()}_CHAIN_ID`];
  if (networkChainId === undefined) {
    throw new Error(`chainId not found for network ${network}`);
  }

  // ethers decode abi
  const decodedData = hre.ethers.AbiCoder.defaultAbiCoder().decode(
    [ 'uint8', 'uint8', 'uint8', 'address', 'address', 'uint256', 'uint256', 'bytes'],
    data
  );
  //const iface = new hre.ethers.Interface(['function receiveMessage((uint8,uint8,uint8,address,address,uint256,uint256),bytes)']);
  // const functionData = iface.decodeFunctionData('receiveMessage((uint8,uint8,uint8,address,address,uint256,uint256),bytes)', data);

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
  if (crossChainMessage.dstChainId !== parseInt(networkChainId)) {
    console.log(`crossChainMessage.dstChainId ${crossChainMessage.dstChainId} not equal to networkChainId ${networkChainId}, skip`);
    return;
  }
  
  // set provider
  const provider = new hre.ethers.JsonRpcProvider(process.env[`RPC_URL_${network.toUpperCase()}`]);
  // get pk and set an account 
  const pk = process.env[`${network.toUpperCase()}_PRIVATE_KEY`];
  if (pk === undefined) {
    throw new Error(`private key not found for network ${network}`);
  }
  const wallet = new hre.ethers.Wallet(pk, provider);


  // call with function selector and data
  // function receiveMessage((uint8,uint8,uint8,address,address,uint256,uint256),bytes)
  // calculate function selector
  // const functionSelector = hre.ethers.id('receiveMessage((uint8,uint8,uint8,address,address,uint256,uint256),bytes)');
  // call relayAddress with functionSelector and data
  const relayContract = await hre.ethers.getContractAt('CrossChainRelayUpgradeable', relayAddress);
  
  // call with wallet
  const tx = await relayContract.connect(wallet).receiveMessage(crossChainMessage, decodedData[7]);

  tx.wait();
  
  console.log('tx hash: ', tx.hash);
  
}

async function getLatestBlock(network: string, dstNetwork: string, hre: HardhatRuntimeEnvironment) {

    const { ethers } = hre;
    // convert network name to RPC URL env var name, put in uppercase
    const rpcUrlEnvVarName = `RPC_URL_${network.toUpperCase()}`;
    // from dotenv get network provider, e.g. "RINKEBY_RPC_URL"
    const netowrkRpcUrl = process.env[rpcUrlEnvVarName];
    console.log(`network ${network} RPC URL: `, netowrkRpcUrl)

    // get event topics
    const eventTopic = hre.ethers.id(eventSignature);
    console.log(`event topic: `, eventTopic)

    // dstRelayAddress
    const dstRelayAddress = process.env[`${dstNetwork.toUpperCase()}_RELAY_PROXY`];
    if (dstRelayAddress === undefined) {
      throw new Error(`relayAddress not found for network ${dstNetwork}`);
    }
    const relayAddress = process.env[`${network.toUpperCase()}_RELAY_PROXY`];
    if (relayAddress === undefined) {
      throw new Error(`relayAddress not found for network ${network}`);
    }

    // create provider
    const provider = new hre.ethers.JsonRpcProvider(netowrkRpcUrl);

    // get all files match the pattern
    const sentFiles = fs.readdirSync('mockSentMsgs').filter(fn => fn.startsWith(`${network}-`));
    console.log(`files: `, sentFiles)

    // load finished-block from json
    // file name network-finished-block.json
    const fileName = `mockToSendMsgs/${network}-finished-block.json`;
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
        let endBlockNum = blockNumber;
        // maximum 2048 blocks
        if (endBlockNum - crossChainProcessInfo.finishedBlock > 2047) {
          endBlockNum = crossChainProcessInfo.finishedBlock + 2047;
        }
        const logs = await provider.getLogs({
          fromBlock: crossChainProcessInfo.finishedBlock,
          toBlock: endBlockNum,
        });
        // and filter logs by event topic and contract address (relayAddress)
        const myEvents = logs.filter((log) => {
          return log.topics.includes(eventTopic) && log.address === relayAddress;
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
        // save every event to a file
        // with name mockToSendMsgs/network-blockNumber-eventIndex.json
        // e.g. mockToSendMsgs/rinkeby-23783476-0.json
        // myEvents.forEach((log, index) => {
        //   const eventFile = `mockToSendMsgs/${network}-${log.blockNumber}-${log.index}.json`;
        //   console.log(`writing ${eventFile}...`);
        //   // dump log to file
        //   fs.writeFileSync(eventFile, JSON.stringify(log, null, 2));
        // });
        
        // process all events
        for (let i = 0; i < myEvents.length; i++) {
          const log = myEvents[i];
          const eventFile = `${network}-${log.blockNumber}-${log.index}.json`;
          // if eventFile in sentFiles, skip
          if (sentFiles.includes(eventFile)) {
            console.log(`${eventFile} already processed, skip`);
            continue;
          }
          await sendMsg(dstNetwork, log.data, dstRelayAddress, hre);
          // dump log to file
          fs.writeFileSync(`mockSentMsgs/${eventFile}`, JSON.stringify(log, null, 2));
        }

        crossChainProcessInfo.finishedBlock = endBlockNum + 1;
        // write back to file
        fs.writeFileSync(fileName, JSON.stringify(crossChainProcessInfo, null, 2));

      } else {
        await new Promise(r => setTimeout(r, 1000));
      }
    }


  }


task("mockCrossChain",
  "mock cross-chain message passing",
  async (taskArgs: any, hre: HardhatRuntimeEnvironment) => {
    // print ethers version
    console.log('ethers version: ', hre.ethers.version);
    // get src network and dst network from taskArgs
    const { network1, network2} = taskArgs;
   
    // start too threads and then wait for them to finish
    // getLatestBlock(network1, network2, hre);
    // getLatestBlock(network2, network1, hre);
    await Promise.all([
      getLatestBlock(network1, network2, hre),
      getLatestBlock(network2, network1, hre),
    ]);
    

}).addParam("network1", "The cross-chain source network")
  .addParam("network2", "The cross-chain destination network")
  

// command of calling this task
// npx hardhat mockCrossChain --src-network orderly --dst-network fuji