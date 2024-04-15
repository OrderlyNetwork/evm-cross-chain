import { getContractAbi, abiToSignature, getFunctionSignature, genFunctionCalldata } from "./getContractAbi";

import { expect } from "chai";

describe("getContractAbi", () => {
    // normal case
    it("should return abi", () => {
        const abi = getContractAbi("CCRelay", "removeCaller");
        expect(abi).to.deep.equal({
            "inputs": [
              {
                "internalType": "address",
                "name": "caller",
                "type": "address"
              }
            ],
            "name": "removeCaller",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
          });
    });
    // error case
    it("should throw error", () => {
        expect(() => getContractAbi("CCRelay", "removeCaller1")).to.throw("abi not found, contractName: CCRelay, funcName: removeCaller1");
    });
});

describe("abiToSignature", () => {
    // normal case
    it("should return signature", () => {
        const abi = getContractAbi("CCRelay", "removeCaller");
        const signature = abiToSignature(abi);
        expect(signature).to.equal("removeCaller(address)");
    });
    // error case
    it("should throw error", () => {
        const abi = getContractAbi("CCRelay", "removeCaller");
        abi['inputs'][0]['type'] = 'tuple';
        abi['inputs'][0]['components'] = [
          {
            "internalType": "address",
            "name": "caller",
            "type": "address"
          },
          {
            "internalType": "tuple",
            "name": "caller",
            "type": "tuple"
          }
        ];
        expect(() => abiToSignature(abi)).to.throw("tuple in tuple not supported");
    });
});

describe("getFunctionSignature", () => {
    // normal case
    it("should return signature", () => {
        const signature = getFunctionSignature("CCRelay", "removeCaller");
        expect(signature).to.equal("removeCaller(address)");
    });
    // error case
    it("should throw error", () => {
        expect(() => getFunctionSignature("CCRelay", "removeCaller1")).to.throw("abi not found, contractName: CCRelay, funcName: removeCaller1");
    });
});

describe("genFunctionCalldata", () => {
    // normal case
    it("should return calldata", () => {
        const calldata = genFunctionCalldata("CCRelay", "removeCaller", ["0x1111111111111111111111111111111111111111"]);
        expect(calldata).to.equal("0xeef21cd20000000000000000000000001111111111111111111111111111111111111111");
    });
    // error case
    it("should throw error", () => {
      //should throw an error, but any error is fine
      expect(() => genFunctionCalldata("CCRelay", "removeCaller", ["0x11111"])).to.throw("encodeFunctionData error, signature: removeCaller(address), params: 0x11111");
    });
});

