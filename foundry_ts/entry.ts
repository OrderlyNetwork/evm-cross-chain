
import { upgradeRelay } from "./methods/upgradeRelay";
import { generalMethod } from "./methods/general_method";
import { checkArgs} from "./helper";

const argv = require('minimist')(process.argv.slice(2));

if (argv.method === undefined) {
    console.error(`Usage: ts-node foundry_ts/entry.ts --method <method> [--broadcast <true|false>] ...`);
    process.exit(1);
}

if (argv.broadcast === undefined) {
    argv.broadcast = false;
}

console.log("argv: ");
console.log(argv);

// add new method here

if (argv.method === "upgradeRelay") {
    const required_flags = ["env", "network", "broadcast"];
    checkArgs(argv.method, argv, required_flags);
    // upgradeRelay(argv.env, argv.network);
    generalMethod(argv.method, argv.env, argv.network, argv.broadcast);
}

if (argv.method === "checkFlags") {
    console.log("doing nothing");
}