import * as dotenv from "dotenv";
dotenv.config();
import { HardhatUserConfig, task } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ethers";
import "hardhat-deploy";
import "hardhat-deploy-ethers";
import "hardhat-deploy-tenderly";
import '@openzeppelin/hardhat-upgrades';
// import "@nomicfoundation/hardhat-foundry";
//import * as tdly from "./tenderly-hardhat/src";
//tdly.setup();

import "./tasks/accounts";
import "./tasks/sampleTask";
import "./tasks/balance";
import "./tasks/deployLock";
import "./tasks/setupRelay";
import "./tasks/sendPing";
import "./tasks/mockCrossChain";

function getAccount(networkName: string) {
  console.log('using network: ', networkName)
  if (networkName) {
    const pk = process.env[networkName.toUpperCase() + "_PRIVATE_KEY"]
    if (pk && pk !== '') {
      return [pk]
    }
  }

  return { mnemonic: 'test test test test test test test test test test test junk' }
}

function getRpcUrl(networkName: string) {
  if (networkName) {
    const url = process.env["RPC_URL_" + networkName.toUpperCase()];
    if (url && url !== '') {
      return url
    } else {
      throw new Error('RPC_URL_' + networkName.toUpperCase() + ' not found');
    }
  }
}

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      }
    }
  },
  networks: {
    ethereum: {
      url: getRpcUrl('ethereum'),
      chainId: 1,
      accounts: getAccount('ethereum'),
    },
    bsc: {
      url: getRpcUrl('bsc'),
      chainId: 56,
      accounts: getAccount('bsc'),
    },
    fuji: {
      url: getRpcUrl('fuji'),
      chainId: 43113,
      saveDeployments: true,
      accounts: getAccount('fuji'),
    },
    orderly: {
      url: getRpcUrl('orderly'),
      chainId: 986532,
      accounts: getAccount('orderly'),
    },
    orderlyop: {
      url: getRpcUrl('orderlyop'),
      chainId: 4460,
      accounts: getAccount('orderlyop'),
    },
    arbitrumgoerli: {
      url: getRpcUrl('arbitrumgoerli'),
      chainId: 421613,
      accounts: getAccount('arbitrumgoerli'),
    }
  },
  tenderly: {
    project: 'project',
    username: 'Lulu',
  }
};

export default config;
