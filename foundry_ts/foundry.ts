// Timestamp: 10/16/2019 7:50 PM
import { exec } from "shelljs";
import * as fs from "fs";
import {foundry_script_folder} from "./utils/const";
import { findFoundryScript } from "./utils/findFoundryScript";

// foundry wrapper function, send an operation method name to the function and run a command
export function foundry_wrapper(method_name: string, broadcast: boolean, simulate: boolean) {
    let broadcastFlag = broadcast ? "--broadcast" : "";
    const foundryScriptPath = findFoundryScript(foundry_script_folder, method_name);
    if (!foundryScriptPath) {
        console.log(`Cannot find ${method_name} script in ${foundry_script_folder}`);
        process.exit(1);
    }
    let command = `forge script ${foundryScriptPath} -vvvv ${broadcastFlag}`;
    console.log(`Running ${method_name} script: ${command}`);

    if (simulate) {return;}

    // run the command
    let result = exec(command);

    // if the command is not successful, print the error message
    if (result.code != 0) {
        // command failure
        console.log(`Error running ${method_name} script: ${command}`)
        // print the error message
        console.log(result.stderr);
        // exit the program
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
        env_data += `\n${var_name}=${value}`;
    }
    // console.log(env_data);
    // save back to .env
    fs.writeFileSync(env_file, env_data);
}