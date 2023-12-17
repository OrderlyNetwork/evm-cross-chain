import { JsonRpcProvider, Log} from "ethers";
import { parseStoredPayload } from "./lzStoredPayload";

export async function getEvents(provider: JsonRpcProvider, startBlock: number, endBlock: number) : Promise<Array<Log>> {
        return provider.getLogs({
          fromBlock: startBlock, 
          toBlock: endBlock 
        });

}

export function filterEventTopic(logs: Array<Log>, eventSignature: string) : Array<Log> {
    const filterLogs = logs.filter((log) => {
        return log.topics.includes(eventSignature);
        }
    );
    return filterLogs;
}

export function filterStoredPayload(logs: Array<Log>, srcAddress: string) : Array<Log> {
    return logs.filter((log) => {
        const storedPayload = parseStoredPayload(log.data);
        console.log("storedPayload.srcAddress:");
        console.log(storedPayload.srcAddress);
        console.log(srcAddress);
        // compare two hex strings
        if (storedPayload.srcAddress.toLocaleLowerCase() === srcAddress.toLocaleLowerCase()) {
            return true;
        } else {
            return false;
        }
    });
}