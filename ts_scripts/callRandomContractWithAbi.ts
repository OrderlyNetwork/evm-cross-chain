import { ethers } from 'ethers';
import fs from 'fs';
import path from 'path';

// Use minimist to parse command line arguments
const argv = require('minimist')(process.argv.slice(2), {"string": ["abiPath", "contract", "network", "funcName", "params"]});

// Load the ABI from a JSON file
const abiPath = argv.abiPath;
let contractABI = JSON.parse(fs.readFileSync(abiPath, 'utf8'));
// if contractABI is an json object, then get the abi from the object
if (contractABI.abi) {
  contractABI = contractABI.abi;
}

async function callContractFunction(contractAddress: string, provider: ethers.JsonRpcProvider, funcName: string, params: any[]) {
  // Create a new contract instance with the provider and ABI
  const contract = new ethers.Contract(contractAddress, contractABI, provider);

  // Dynamically call the function based on funcName and params
  const result = await contract[funcName](...params);
  console.log(`Result for ${funcName} with params ${params}:`, result);
}

// Example usage setup
import { getRpcUrl } from '../foundry_ts/utils/envUtils';
const rpcUrl = getRpcUrl(argv.network);

const contractAddress = argv.contract;
const provider = new ethers.JsonRpcProvider(rpcUrl);
const funcName = argv.funcName;

// Parse and prepare params
let params = argv.params ? argv.params.split(',') : [];
console.log('Params:', params);

callContractFunction(contractAddress, provider, funcName, params)
  .then(() => console.log('Function call successful.'))
  .catch((error) => console.error('Error calling function:', error));
``
