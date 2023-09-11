
import { deployRelay } from "./methods/deployRelay";
import { generalMethod } from "./methods/generalMethod";
import { relayMsgTest } from "./methods/relayMsgTest";
import { checkArgs} from "./helper";
import { retryPayload } from "./methods/retryPayload";
import { transferNativeToken } from "./methods/transferNativeToken";
import { setupDeployJson } from "./utils/setup_json";

const argv = require('minimist')(process.argv.slice(2), {'string': "data"});

if (argv.method === undefined) {
    console.error(`Usage: ts-node foundry_ts/entry.ts --method <method> [--broadcast <true|false>] ...`);
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

// general methods only requires env, network, broadcast, simulate
const general_methods = ["upgradeRelay", "setRelayChainId"];

// argv.method in general_methods
if (general_methods.includes(argv.method)) {
    const required_flags = ["env", "network", "broadcast", "simulate"];
    checkArgs(argv.method, argv, required_flags);
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

if (argv.method === "deployRelay") {
    const required_flags = ["env", "network", "broadcast"];
    checkArgs(argv.method, argv, required_flags);
    deployRelay(argv.env, argv.network, argv.broadcast, argv.simulate);
}

if (argv.method === "transferNativeToken") {
    const required_flags = ["network", "to", "ether", "broadcast"];
    checkArgs(argv.method, argv, required_flags);
    transferNativeToken(argv.network, argv.to, argv.ether, argv.broadcast);
}

// TODO
if (argv.method === "deployAndSetupAnEnv") {

}

// some situations require to run multiple operations
// 1. setup an environment, like qa, dev, prod, or staging, which requires to deploy and setup relays and cc managers
// 2. add an additional vault chain for an env, deploy and setup both relay and cc manager, and update neccessary relay and cc managers on other chains