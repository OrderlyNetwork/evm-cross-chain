
export function findFile(search_path: string, filename: string) : string | undefined {
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
            const result = findFile(file_path, filename);
            if (result) {
                return result;
            }
        } else if (file_path.endsWith(`${filename}`)) {
            return file_path;
        }
    }

    // not found
    return undefined;
}