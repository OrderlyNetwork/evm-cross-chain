import { set } from "shelljs";
import { checkArgs } from "../helper";
import { addArgvType } from "../utils/config";
import { set_env_var } from "../foundry";
import { genTxJsonFileName } from "../utils/getContractAbi";


const method_name = "safeSignProposal";


function safeSignProposalWithArgv(argv: any) {
    const required_flags = ["env", "network", "contractName", "funcName"];
    checkArgs(argv.method, argv, required_flags);
    safeSignProposal(argv.env, argv.network, argv.contractName, argv.funcName);
}

export function safeSignProposal(env: string, network: string, contractName: string, funcName: string) {
    const txJsonName = genTxJsonFileName(env, network, contractName, funcName);
    const path = "./data/" + txJsonName;

    set_env_var(method_name, "env", env);
    set_env_var(method_name, "network", network);
    set_env_var(method_name, "txFile", path);
}