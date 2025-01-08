import { readJsonValue } from './utils/json_reader';
import { updateJson } from './utils/json_writer';
import { updateEnv } from './utils/env_writer';
import { promptUser } from './utils/command_prompt';
import * as fs from 'fs/promises';
import * as path from 'path';

interface ChainConfig {
  envName: string;
  chainName: string;
}

async function fileExists(filePath: string): Promise<boolean> {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function prepareNewVaultDeployJson(env: string, chainName: string) {
  const path1 = "config/cross-chain-manager.json";
  const path2 = "config/cross-chain-relay.json";

  const { value: proxy, exists: proxyExists } = await readJsonValue(path1, `.${env}.${chainName}.proxy`);
  if (!proxyExists) {
    await updateJson(path1, `.${env}.${chainName}.proxy`, "0x0000000000000000000000000000000000000000", { force: true });
    await updateJson(path1, `.${env}.${chainName}.owner`, "0x0000000000000000000000000000000000000000", { force: true });
    await updateJson(path1, `.${env}.${chainName}.manager`, "0x0000000000000000000000000000000000000000", { force: true });
    await updateJson(path1, `.${env}.${chainName}.role`, "vault", { force: true });
  }

  const { value: relay, exists: relayExists } = await readJsonValue(path2, `.${env}.${chainName}.proxy`);
  if (!relayExists) {
    await updateJson(path2, `.${env}.${chainName}.proxy`, "0x0000000000000000000000000000000000000000", { force: true });
    await updateJson(path2, `.${env}.${chainName}.owner`, "0x0000000000000000000000000000000000000000", { force: true });
    await updateJson(path2, `.${env}.${chainName}.relay`, "0x0000000000000000000000000000000000000000", { force: true });
  }

}

async function checkAndUpdateJsonValue(
  jsonPath: string,
  key: string,
  type: 'string' | 'number' | 'boolean',
  checkOnly = false
): Promise<void> {
    console.log(`Check and update ${key} in ${jsonPath}`);
    const { value, exists } = await readJsonValue(jsonPath, key);

    if (checkOnly) {
        if (exists) {
            console.log(`${key} exists in ${jsonPath}`);
        } else {
            throw new Error(`${key} does not exist in ${jsonPath}, please set it manually`);
        }
        return;
    }

    let shouldUpdate = true;

    if (exists) {
        shouldUpdate = await promptUser<boolean>(`Current value of ${key} in ${jsonPath} is ${value}, update?`, 'boolean', { defaultValue: 'false' });
    }

    if (shouldUpdate) {
        const newValue = await promptUser(`Enter new value for ${key} in ${jsonPath}`, type);
        await updateJson(jsonPath, key, newValue, { force: true });
    }

    return;
}

async function checkAndUpdateEnvValue(
  envPath: string,
  key: string,
  description: string,
  nonInteractive = false
): Promise<void> {
  try {
    const envContent = await fs.readFile(envPath, 'utf-8');
    const exists = envContent.includes(key);

    if (exists) {
      const shouldUpdate = nonInteractive ? false : 
        await promptUser<boolean>(`${key} exists. Update?`, 'boolean', { defaultValue: 'false' });
      
      if (shouldUpdate) {
        const newValue = await promptUser<string>(`Enter new value for ${key}`, 'string', {
          defaultValue: '',
        });
        await updateEnv(envPath, key, newValue, { force: true });
      }
    } else {
      const value = await promptUser<string>(`Enter value for ${key}: ${description}`, 'string', {
        defaultValue: '',
      });
      await updateEnv(envPath, key, value, { force: true });
    }
  } catch (error) {
    console.error(`Error updating ${key}:`, error);
    throw error;
  }
}

async function setupChainConfig(envName: string, chainName: string): Promise<void> {
  const config: ChainConfig = {
    envName,
    chainName,
  };

  // add emojis
  console.log(`\u{1F600} Setting up configuration for ${config.chainName} in ${config.envName} environment...\n`);
  console.log("================================================")

  // 0. Prepare new vault deploy json
  console.log(`\nStep 0: Preparing new vault deploy json for ${config.chainName} in ${config.envName} environment\n`);
  await prepareNewVaultDeployJson(config.envName, config.chainName);

  // 1. Remind about private key
  console.log(`\nStep 1: Reminder: Please ensure PRIVATE_KEY is set in .env for ${config.envName} environment\n`);
  
  // 2. Handle project-related.json configuration
  const vaultKey= `.dev.${chainName}.vault`;
  const projectJsonConfigPath = 'config/project-related.json';
  
  console.log(`\nStep 2: Checking ${vaultKey} in ${projectJsonConfigPath}\n`);
  if (await fileExists(projectJsonConfigPath)) {
    await checkAndUpdateJsonValue(
        projectJsonConfigPath,
        vaultKey,
        'string',
    );
  }

  // 3. Check token-decimals.json default value
  const tokenDecimalsPath = 'config/token-decimals.json';
  console.log(`\nStep 3: Checking default value in ${tokenDecimalsPath}\n`);
  if (await fileExists(tokenDecimalsPath)) {
    try {
        await checkAndUpdateJsonValue(
            tokenDecimalsPath,
            '.default',
            'number',
            true
        );
    } catch (error) {
        console.error('Error checking token-decimals.json:', error);
        return;
    }
  }

  // 4. Handle .env configurations
  const envPath = `.env`;
  const envConfigs = [
    {
      key: `${config.chainName}_RPC_URL`.toUpperCase(),
      description: 'RPC URL for the chain',
    },
    {
      key: `${config.chainName}_CHAIN_ID`.toUpperCase(),
      description: 'Chain ID',
    },
    {
      key: `${config.chainName}_LZ_CHAIN_ID`.toUpperCase(),
      description: 'LayerZero Chain ID',
    },
    {
      key: `${config.chainName}_ENDPOINT`.toUpperCase(),
      description: 'Chain endpoint',
    },
    {
      key: `${config.chainName}_EXPLORER_TYPE`.toUpperCase(),
      description: 'Explorer type (e.g., etherscan)',
    },
    {
      key: `${config.chainName}_EXPLORER_API_URL`.toUpperCase(),
      description: 'Explorer API URL',
    },
    {
      key: `${config.chainName}_ETHERSCAN_API_KEY`.toUpperCase(),
      description: 'Explorer API key',
    },
  ];

  let step = 4;
  for (const config of envConfigs) {
    console.log(`\nStep ${step}: Checking ${config.key} in ${envPath}\n`);
    await checkAndUpdateEnvValue(envPath, config.key, config.description);
    step++;
  }

  console.log('\nConfiguration setup completed successfully!');
}

// CLI interface
if (require.main === module) {
  const args = process.argv.slice(2);
  if (args.length !== 2) {
    console.error('Usage: ts-node script/setupChainConfig.ts <env> <chainName>');
    process.exit(1);
  }

  const [env, chainName] = args;
  setupChainConfig(env, chainName).catch((error) => {
    console.error('Error:', error);
    process.exit(1);
  });
}

export { setupChainConfig }; 