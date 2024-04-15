import dotenv from 'dotenv';
// load .env file
dotenv.config();

export function getRpcUrl(network: string): string {
    return process.env["RPC_URL_" + network.toUpperCase()] as string;
}

export function getExplorerApiUrl(network: string): string {
    return process.env[ network.toUpperCase() + "_EXPLORER_API_URL" ] as string;
}

export function getChainId(network: string): number {
    return parseInt(process.env[network.toUpperCase() + "_CHAIN_ID"] as string);
}

export function getLzChainId(network: string): number {
    return parseInt(process.env[network.toUpperCase() + "_LZ_CHAIN_ID"] as string);
}

export function getEtherscanApiKey(network: string): string {
    return process.env[network.toUpperCase() + "_ETHERSCAN_API_KEY"] as string;
}

export function getPk(network: string): string {
    return process.env[network.toUpperCase() + "_PRIVATE_KEY"] as string;
}

export function getEndpoint(network: string): string {
    return process.env[network.toUpperCase() + "_ENDPOINT"] as string;
}

export function getExporerType(network: string): "etherscan" | "blockscout" | undefined {
    return process.env[network.toUpperCase() + "_EXPLORER_TYPE"] as "etherscan" | "blockscout" | undefined;
}