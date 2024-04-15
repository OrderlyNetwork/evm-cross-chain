import { ethers } from "ethers";
import { genFunctionCalldata, genTxJsonFileName, getContractAbi } from "../utils/getContractAbi";
import { getContractAddress } from "../utils/getDeployData";
import { addArgvType, addOperation } from "../utils/config";
import { checkArgs } from "../helper";
import { foundry_wrapper, set_env_var } from "../foundry";

const method_name = "safeSubmitTx";

function safeSubmitTxWithArgv(argv: any) {
    const required_flags = ["network", "txFile"];
    checkArgs(argv.method, argv, required_flags);
    safeSubmitTx(argv.network, argv.txFile, argv.broadcast, argv.simulate);
}

export function safeSubmitTx(network: string, txFile: string, broadcast: boolean, simulate: boolean) {
    set_env_var(method_name, "txFile", txFile);
    set_env_var(method_name, "network", network);
    foundry_wrapper(method_name, broadcast, simulate);
}

addOperation(method_name, safeSubmitTxWithArgv);