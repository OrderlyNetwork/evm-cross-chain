import { foundry_script_folder } from "./const";

export function findFoundryScript(search_path: string, method_name: string) : string | undefined {
    // find under foundry_script_folder for `${method_name}.s.sol`
    // search recursively
    const fs = require("fs");
    const path = require("path");
    const files = fs.readdirSync(search_path);
    for (const file of files) {
        const file_path = path.join(search_path, file);
        const stat = fs.lstatSync(file_path);
        if (stat.isDirectory()) {
            // recurse
            const result = findFoundryScript(file_path, method_name);
            if (result) {
                return result;
            }
        } else if (file_path.endsWith(`${method_name}.s.sol`)) {
            return file_path;
        }
    }

    // not found
    return undefined;
}

// console.log(findFoundryScript(foundry_script_folder, "setRelayTrustedRemote"));