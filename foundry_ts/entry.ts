
import { upgradeRelay } from "./methods/upgradeRelay";
import { generalMethod } from "./methods/generalMethod";
import { relayMsgTest } from "./methods/relayMsgTest";
import { checkArgs} from "./helper";
import { retryPayload } from "./methods/retryPayload";

const argv = require('minimist')(process.argv.slice(2), {'string': "data"});

if (argv.method === undefined) {
    console.error(`Usage: ts-node foundry_ts/entry.ts --method <method> [--broadcast <true|false>] ...`);
    process.exit(1);
}

// fill default values
if (argv.broadcast === undefined) {
    argv.broadcast = false;
}
if (argv.simulate === undefined) {
    argv.simulate = false;
}

console.log("argv: ");
console.log(argv);

// add new method here

if (argv.method === "upgradeRelay") {
    const required_flags = ["env", "network", "broadcast", "simulate"];
    checkArgs(argv.method, argv, required_flags);
    //upgradeRelay(argv.env, argv.network, argv.broadcast, argv.simulate);
    generalMethod(argv.method, argv.env, argv.network, argv.broadcast, argv.simulate);
}

if (argv.method === "checkFlags") {
    console.log("doing nothing");
}

if (argv.method === "relayMsgTest") {
    const required_flags = ["env", "srcNetwork", "dstNetwork", "broadcast"];
    checkArgs(argv.method, argv, required_flags);

    relayMsgTest(argv.env, argv.srcNetwork, argv.dstNetwork, argv.broadcast);
}

if (argv.method === "retryPayload") {
    const required_flags = ["env", "network", "broadcast", "data"];
    checkArgs(argv.method, argv, required_flags);
    retryPayload(argv.network, argv.data, argv.broadcast);
}