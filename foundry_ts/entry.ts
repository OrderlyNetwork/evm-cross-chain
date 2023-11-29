
import { operation_map, argv_type_config } from "./utils/config";
import "./methods";

const argv = require('minimist')(process.argv.slice(2), argv_type_config);

if (argv.method === undefined) {
    console.error(`Usage: ts-node foundry_ts/entry.ts --method <method> [--broadcast] [--simulate] ...`);
    process.exit(1);
}

// fill default values
// if broadcast is not activated, foundry script will not send tx to networks
if (argv.broadcast === undefined) {
    argv.broadcast = false;
}

// under simulate mode, foundry script will not be executed
if (argv.simulate === undefined) {
    argv.simulate = false;
}

console.log("argv: ");
console.log(argv);

console.log("available operations: ");
console.log(operation_map);
const func = operation_map.get(argv.method)
if (func) {
    func(argv); 
} else {
    console.error(`method ${argv.method} is not found`);
    process.exit(1);
}

// some situations require to run multiple operations
// 1. setup an environment, like qa, dev, prod, or staging, which requires to deploy and setup relays and cc managers
// 2. add an additional vault chain for an env, deploy and setup both relay and cc manager, and update neccessary relay and cc managers on other chains
