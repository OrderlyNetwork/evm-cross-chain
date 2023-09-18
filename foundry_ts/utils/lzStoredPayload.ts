import { Log, AbiCoder, ethers} from "ethers";

// solidity struct
// uint16 srcChainId, bytes srcAddress, address dstAddress, uint64 nonce, bytes payload, bytes reason
interface StoredPayload {
    srcChainId: number;
    srcAddress: string;
    dstAddress: string;
    nonce: number;
    payload: string;
    reason: string;
}

export function getPayloadStoredEventTopic() : string {
    const sig = 'PayloadStored(uint16,bytes,address,uint64,bytes,bytes)';
    const eventTopic = ethers.id(sig);
    return eventTopic;
}

export function parseStoredPayload(data: string): StoredPayload {

  const decodedData = AbiCoder.defaultAbiCoder().decode(
    ['uint16', 'bytes', 'address', 'uint64', 'bytes', 'bytes'],
    data
  );

    const srcChainId = decodedData[0];
    const srcAddress = decodedData[1];
    const dstAddress = decodedData[2];
    const nonce = decodedData[3];
    const payload = decodedData[4];
    const reason = decodedData[5];

    const storedPayload: StoredPayload = {
        srcChainId,
        srcAddress,
        dstAddress,
        nonce,
        payload,
        reason
    }; 

    return storedPayload;
}