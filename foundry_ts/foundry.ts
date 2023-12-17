// Timestamp: 10/16/2019 7:50 PM
import { exec, set } from "shelljs";
import * as fs from "fs";
import {foundry_script_folder} from "./utils/const";
import { findFoundryScript } from "./utils/findFoundryScript";
import { getEtherscanApiKey, getExplorerApiUrl, getRpcUrl } from "./utils/envUtils";


// foundry wrapper function, send an operation method name to the function and run a command
export function foundry_wrapper(method_name: string, broadcast: boolean, simulate: boolean, verify: boolean = false, explorer: "etherscan" | "blockscout" = "etherscan", network: string = "none") {
    let broadcastFlag = broadcast ? "--broadcast" : "";
    const foundryScriptPath = findFoundryScript(foundry_script_folder, method_name);
    if (!foundryScriptPath) {
        console.log(`Cannot find ${method_name} script in ${foundry_script_folder}`);
        process.exit(1);
    }
    
    let verifyFlag = verify ? " --verify --legacy" : "";
    if (verify) {
        const explorerApiUrl = getExplorerApiUrl(network);
        const explorerRpcUrl = getRpcUrl(network);
        if (explorer === "etherscan") {
            const apiKey = getEtherscanApiKey(network);
            verifyFlag = ` -f ${explorerRpcUrl} --verifier-url ${explorerApiUrl} --etherscan-api-key ${apiKey} ` + verifyFlag;
        } else if (explorer === "blockscout") {
            verifyFlag = ` -f ${explorerRpcUrl} --verifier blockscout --verifier-url ${explorerApiUrl} ` + verifyFlag;
        } else {
            console.log(`Cannot find explorer type ${explorer}`);
            process.exit(1);
        }
    }

    let command = `source .env && forge script ${foundryScriptPath} ${verifyFlag} -vvvv ${broadcastFlag}`;
    console.log(`Running ${method_name} script: ${command}`);

    if (simulate) {return;}

    const max_retry = 5;
    let success = false;
    let try_cnt = 0;
    // run the command
    while (try_cnt++ < max_retry) {
        let result = exec(command);
        if (result.code == 0) {
            // command success
            success = true;
            break;
        }
        // if the command is not successful, print the error message
        if (result.code != 0) {
            // command failure
            console.log(`Error running ${method_name} script: ${command}`)
            // print the error message
            console.log(result.stderr);
            console.log("Retrying...");
        }
    }

    if (!success) {
        console.log(`Error running ${method_name} script: ${command}`)
        console.log(`Failed after ${max_retry} retries`)
        console.log("Exiting...");
        process.exit(1);
    }

}

export function set_env_var(method_name: string, var_name: string, value: string) {
    // var_name all caps
    var_name = `FS_${method_name}_${var_name}`;
    
    console.log("setting env var: " + var_name + " to " + value);

    // open the .env file
    let env_file = ".env";
    // read the .env file
    let env_data = fs.readFileSync(env_file, 'utf8');
    // if the variable is already in the .env file, replace the value
    if (env_data.includes(var_name)) {
        // replace the value
        // using regex to replace the line
        // it should also with start of the line
        env_data = env_data.replace(new RegExp(`^${var_name}=.*`, "gm"), `${var_name}=${value}`);
    } else {
        // if the variable is not in the .env file, add the variable and value
        env_data = `${var_name}=${value}\n` + env_data;
    }
    // console.log(env_data);
    // save back to .env
    fs.rmSync(env_file);
    fs.writeFileSync(env_file, env_data);

    // sleep
    // setTimeout(() => {}, 5000);
    exec(`source ${env_file}`)
}