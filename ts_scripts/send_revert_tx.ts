const { ethers } = require('ethers');
// load env


// RPC provider URL
const rpcUrl = 'https://l2-orderly-l2-4460-sepolia-8tc3sd7dvy.t.conduit.xyz'
const provider = new ethers.JsonRpcProvider(rpcUrl);

// Wallet private key (keep this secure)
// from .env ORDERLYOP_PRIVATE_KEY
const privateKey = process.env.ORDERLYOP_PRIVATE_KEY as string;
// print part of key
console.log('privateKey: ', privateKey.slice(0, 10));
const wallet = new ethers.Wallet(privateKey, provider);

// The contract address and ABI (for interacting with a contract)
const contractAddress = '0x449Af90004cC17018C5e5608f26312e16F184530';
const contractABI = [
    {
      "inputs": [],
      "name": "revertFunc",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ]
// Create a contract instance
const contract = new ethers.Contract(contractAddress, contractABI, wallet);

// Example function call
async function sendTransaction() {
  try {
    const txResponse = await contract.revertFunc( {
        gasLimit: 300000,
        // gasPrice: 1000000000
    });
    console.log('Transaction response:', txResponse);

    // Optionally wait for the transaction to be mined
    const receipt = await txResponse.wait();
    console.log('Transaction receipt:', receipt);
  } catch (error:any) {
    console.error('Error in transaction:', error.message);
    // This error will be logged if the transaction fails to send or reverts.
    // However, the transaction itself is sent to the mempool regardless of this catch block.
  }
}

sendTransaction();
