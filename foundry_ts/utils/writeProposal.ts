import { exec } from "shelljs";

interface SafeProposal {
    to: string;
    value: string;
    method: string;
    params: string[];
    operation: number;
}

export function writeToProposal(filename: string, env: string, network: string, to: string, value: string, method: string, params: string[]) {
    const fs = require('fs');
    // get timestamp string in milliseconds
    const date = new Date();
    const timestamp = date.getTime();

    // mkdir -p proposal
    fs.mkdirSync("proposal", { recursive: true });

    // rm all files under proposal folder
    const rmCmd = "rm ./proposal/*"
    // exec(rmCmd);

    const filePath = `proposal/${env}_${network}_${filename}_${timestamp}.json`;

    // construct proposal
    const proposal: SafeProposal = {
        to: to,
        value: value,
        method: method,
        params: params,
        operation: 0
    }

    const jsonString = JSON.stringify(proposal);

    // write jsonString to filePath
    fs.writeFileSync(filePath, jsonString);

}