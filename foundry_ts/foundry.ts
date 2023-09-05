// Timestamp: 10/16/2019 7:50 PM
import { exec } from "shelljs";
import * as fs from "fs";
import {foundry_script_folder} from "./const";

// foundry wrapper function, send an operation method name to the function and run a command
export function foundry_wrapper(method_name: string, broadcast: boolean = false) {
    let broadcastFlag = broadcast ? "--broadcast" : "";
    let command = `forge script ${foundry_script_folder}/${method_name}.s.sol -vvvv ${broadcastFlag}`;

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
    // open the .env file
    let env_file = ".env";
    // read the .env file
    let env_data = fs.readFileSync(env_file, 'utf8');
    // if the variable is already in the .env file, replace the value
    if (env_data.includes(var_name)) {
        // replace the value
        env_data = env_data.replace(`${var_name}=${process.env[var_name]}`, `${var_name}=${value}`);
    } else {
        // if the variable is not in the .env file, add the variable and value
        env_data += `\n${var_name}=${value}`;
    }
    // save back to .env
    fs.writeFileSync(env_file, env_data);
}