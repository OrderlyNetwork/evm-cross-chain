import { addOperation } from "../utils/config";
import { set_env_var, foundry_wrapper } from "../foundry";
import { checkArgs } from "../helper";
import { getEndpoint, getPk, getRpcUrl } from "../utils/envUtils";
import { parseStoredPayload } from "../utils/lzStoredPayload";

// current file name
const method_name = "retryPayloadHH";

export function retryPayloadHHWithArgv(argv: any) {
    const required_flags = ["network", "data"];
    checkArgs(method_name, argv, required_flags);
    retryPayloadHH(argv.network, argv.data, argv.broadcast, argv.simulate);
}

export function retryPayloadHH(network: string, data: string, broadcast: boolean, simulate: boolean) {

    const ethers = require('ethers');
    const endpoint = getEndpoint(network);
    const rpc = getRpcUrl(network);
    const provider = new ethers.JsonRpcProvider(rpc);
    const pk = getPk(network);
    const wallet = new ethers.Wallet(pk, provider);

    const payloadData = parseStoredPayload(data);
    // call the contract on endpoint address, using the contract interface
    const contract = new ethers.Contract(endpoint,
        ['function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external',
        'function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool)'
    ], provider);

    // check if the payload is stored
    contract.connect(wallet).hasStoredPayload(payloadData.srcChainId, payloadData.srcAddress).then((result: any) => {
        console.log(`hasStoredPayload result: ${result}`);
        // if not stored, return
        if (!result) {
            console.log(`payload not stored, return`);
            return;
        }
        contract.connect(wallet).retryPayload(payloadData.srcChainId, payloadData.srcAddress, payloadData.payload, {gasLimit: 1000000}).then((tx: any) => {
            console.log(`tx hash: ${tx.hash}`);
            tx.wait().then((receipt: any) => {
                console.log(`tx receipt: ${JSON.stringify(receipt)}`);
            }).catch((err: any) => {
                console.log(`tx wait error: ${err}`);
            });
        });
    }).catch((err: any) => {
        console.log(`hasStoredPayload error: ${err}`);
    });
    



}

addOperation(method_name, retryPayloadHHWithArgv);

