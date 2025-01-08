import { expect } from "chai";
import { genRawTx } from "./genRawTxJson"
import { getContractAddress } from "../utils/getDeployData";


describe("genRawTsJson", () => {
    // normal case
    it("should return raw ts json", () => {
        genRawTx("dev", "orderlyop", "CCRelay", "upgradeTo", "0xB327191924Fde508AeCAe9F79b253CC5031DceA2", "0");
        // there is a file generated under ./data
        const fs = require('fs');
        const dataDir = './data';
        const txJsonPath = "dev_orderlyop_CCRelay_upgradeTo.json";
        const fileContent = fs.readFileSync(dataDir + '/' + txJsonPath, 'utf8');
        const txJson = JSON.parse(fileContent);

        // check the content of json
        // data 0x3659cfe6000000000000000000000000b327191924fde508aecae9f79b253cc5031dcea2
        expect(txJson['data']).to.equal("0x3659cfe6000000000000000000000000b327191924fde508aecae9f79b253cc5031dcea2");

        const proxyAddress = getContractAddress("dev", "orderlyop", "CCRelay", true);
        expect(txJson['to']).to.equal(proxyAddress);
        
    })
});