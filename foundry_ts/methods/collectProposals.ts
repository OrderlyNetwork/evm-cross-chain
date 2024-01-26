import { addOperation } from "../utils/config";
import { set_env_var, foundry_wrapper } from "../foundry";
import { checkArgs } from "../helper";
import { number } from "yargs";
import path from "path";
import { exec } from "child_process";

const SafeTasksNetworkMapping = {
    "orderlyop": "orderlysepolia",
    "arbitrumgoerli": "arbgoerli",
    "opgoerli": "opgoerli",
    "arbsepolia": "arbsepolia",
    "opsepolia": "opsepolia",
    "mumbai": "mumbai",
    "orderlymain": "orderly",
    "arbitrum": "arbitrum",
    "optimism": "optimism",
    "polygon": "polygon"
}

const SafeEnvzMapping = {
    "dev": "dev",
    "qa": "qa",
    "staging": "staging",
    "production": "prod"
}

const method_name = "collectProposals";

export function collectProposalsWithArgv(argv: any) {
    const required_flags = ["env", "network", "intent", "path"]
    checkArgs(argv.method, argv, required_flags);
    collectProposals(argv.method, argv.env, argv.network, argv.intent, argv.path);
}

export function collectProposals(method_name: string, env: string, network: string, intent: string, safePath: string) {
    const proposals: any[] = [];

    const fs = require('fs');

    // list all proposals under proposal with prefix env_network
    const allFiles = fs.readdirSync("./proposal");
    const proposalFiles: string[] = [];
    allFiles.forEach((file: string) => {
        if (file.startsWith(`${env}_${network}`)) {
            proposalFiles.push(file);
        }
    });
    console.log(`found ${proposalFiles.length} proposals for ${env}_${network}`);
    console.log(proposalFiles);

    // read all proposals as json and put them into proposals array
    proposalFiles.forEach((file: string) => {
        const filePath = `./proposal/${file}`;
        const fileContent = fs.readFileSync(filePath, 'utf8');
        const proposal = JSON.parse(fileContent);
        proposals.push(proposal);
    });

    const ccProposalDir = path.join(safePath, "txn/CrossChain");

    // all proposals are under path and start with N0000_DEV
    // find the largest number and add 1 to it
    const filenames = fs.readdirSync(ccProposalDir);
    let largestNumber = -1;
    filenames.forEach((filename: string) => {
        if (filename.startsWith("N")) {
            const proposalNumber = parseInt(filename.substring(1, 5));
            if (proposalNumber > largestNumber) {
                largestNumber = proposalNumber;
            }
        }
    });
    const numberStr = 'N' + (largestNumber + 1).toString().padStart(4, "0");

    const outFilename = `${numberStr}_${env.toLocaleUpperCase()}_${network.toLocaleUpperCase()}_${intent.toLocaleUpperCase()}.json`;

    // write array as json to file
    const outputFilePath = `${ccProposalDir}/${outFilename}`;
    const jsonString = JSON.stringify(proposals, null, 2);

    fs.writeFileSync(outputFilePath, jsonString);

    const safeNetwork = SafeTasksNetworkMapping[network as keyof typeof SafeTasksNetworkMapping];
    const safeEnv = SafeEnvzMapping[env as keyof typeof SafeEnvzMapping];
    const proposalPath = `txn/CrossChain/${outFilename}`

    const chgDirCmd = `cd ${safePath}`;
    const createProposalCmd = `yarn safe propose-multi --network ${safeNetwork} --env ${safeEnv} ${proposalPath}`

    const cmd = `${chgDirCmd} && ${createProposalCmd}`;

    new Promise((resolve, reject) => {
        exec(cmd, (err: any, stdout: any, stderr: any) => {
            if (err) {
                console.log(err);
                reject(err);
            } else {
                console.log(stdout);
                resolve(stdout);
            }
        });
    });

}

addOperation(method_name, collectProposalsWithArgv);