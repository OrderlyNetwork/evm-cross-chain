import { exec } from "shelljs";

/*
 * Cast send wrapper
 * @param env - The environment to use
 * @param network - The network to use
 * @param contractAddress - The address of the contract to send the transaction to
 * @param args - The arguments to pass to the contract
 */
export async function castSend(env: string, network: string, contractAddress: string, value: string, methodAbi: string, args: string[]) {
    const pkVarName = `${env.toUpperCase()}_PK`;
    const rpcVarName = `${network.toUpperCase()}_RPC_URL`;
    const command = `source .env && cast send ${contractAddress} \"${methodAbi}\" ${args.join(" ")} --value ${value} -r $${rpcVarName} --private-key $${pkVarName}`;
    console.log(`Running command: ${command}`);
    // Check if the command runs successfully, if not, throw an error
    const result = exec(command);
    if (result.code != 0) {
        throw new Error(`Command failed: ${result}`);
    }
}

// CLI interface
if (require.main === module) {
    const args = process.argv.slice(2);
    if (args.length < 5) {
        console.error("Usage: ts-node script/forge_wrapper.ts <env> <network> <contractAddress> <value> <methodAbi> <args...>");
        process.exit(1);
    }
    castSend(args[0], args[1], args[2], args[3], args[4], args.slice(5)).catch((error) => {
        console.error('Error:', error);
        process.exit(1);
    });
}