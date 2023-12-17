import { HardhatRuntimeEnvironment } from "hardhat/types";
import { checkArgs } from "../helper";
import { filterEventTopic, filterStoredPayload, getEvents } from "../utils/queryEvent";
import { ethers } from "ethers";
import { getPk, getRpcUrl } from "../utils/envUtils";
import { getPayloadStoredEventTopic } from "../utils/lzStoredPayload";
import { retryPayload } from "./retryPayload";
import { addOperation } from "../utils/config";
import { retryPayloadHH } from "./retryPayloadHH";

const method_name = "monitorPayloadAndRetry"

export function monitorPayloadAndRetryWithArgv(argv: any) {
    const required_flags = ["blockNumber", "network", "data"];
    checkArgs(method_name, argv, required_flags);
    monitorPayloadAndRetry(argv.blockNumber, argv.network, argv.data, argv.broadcast, argv.simulate);
}

export async function monitorPayloadAndRetry(blockNumber: number, network: string, srcAddress: string, broadcast: boolean, simulate: boolean) {
    const provider = new ethers.JsonRpcProvider(getRpcUrl(network));
    // const pk = getPk(network);
    // const wallet = new ethers.Wallet(pk, provider);

    let currentBlockNumber = blockNumber;
    while (true) {
        const latesetBlockNumber = await provider.getBlockNumber();
        if (currentBlockNumber < latesetBlockNumber) { 
            const logs = await getEvents(provider, currentBlockNumber, currentBlockNumber);
            const filteredLogs = filterEventTopic(logs, getPayloadStoredEventTopic());
            const filteredLogs2 = filterStoredPayload(filteredLogs, srcAddress);

            // there should be only one log
            if (filteredLogs2.length > 1) {
                throw new Error(`more than one log found.`);
            }

            if (filteredLogs2.length === 0) {
                console.log(`no log found on block ${currentBlockNumber}`);
            }

            // process each log
            for (const log of filteredLogs2) {
                console.log(`log found on block ${currentBlockNumber}`);
                console.log(`log data: ${log.data}`);
                retryPayloadHH(network, log.data, broadcast, simulate);
            }
            currentBlockNumber += 1;
        } else {
            // wait for 1 second
            console.log(`currentBlockNumber ${currentBlockNumber} is not less than latesetBlockNumber ${latesetBlockNumber}, wait for 1 second`);
            await new Promise(r => setTimeout(r, 1000));
        }
    }

}

addOperation(method_name, monitorPayloadAndRetryWithArgv);