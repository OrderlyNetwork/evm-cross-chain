import dotenv from 'dotenv';
// load .env file
dotenv.config();

export function getRpcUrl(network: string): string {
    return process.env["RPC_URL_" + network.toUpperCase()] as string;
}

export function getPk(network: string): string {
    return process.env[network.toUpperCase() + "_PRIVATE_KEY"] as string;
}

export function getEndpoint(network: string): string {
    return process.env[network.toUpperCase() + "_ENDPOINT"] as string;
}