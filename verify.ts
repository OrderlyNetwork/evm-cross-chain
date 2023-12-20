import { ethers } from "ethers";

const argConfig = {
    "string": ["address", "rpc", "outJsonPath"],
}

// use minimist to parse command line arguments
const argv = require('minimist')(process.argv.slice(2), argConfig);

function verify(address: string, rpc: string, outJsonPath: string) {

    const fs = require('fs');
    // read json file
    const json = JSON.parse(fs.readFileSync(outJsonPath, 'utf8'));

    // if deployedBytecode is empty
    if (json.deployedBytecode.object == "") {
        console.log("no deployedBytecode found in " + outJsonPath + ", please check if the contract is deployed successfully.");
        return;
    }

    const deployedBytecode = json.deployedBytecode.object;

    const provider = new ethers.JsonRpcProvider(rpc);

    provider.getCode(address).then((code) => {
        console.log("Contract address: " + address);
        // console.log("Contract code: " + code);

        console.log("start to verify code ...");
        const addressHex = address.slice(2, address.length).toLocaleLowerCase();
        // find all occurences of address
        const modifyCode = code.replace(new RegExp(addressHex, "g"), "0".repeat(40));
        
        // console.log("Modified code: " + modifyCode)
        // console.log("Contract address hex: " + addressHex)
        // console.log("Deployed code: " + deployedBytecode);

        const onChainCodeHash = ethers.keccak256(modifyCode);
        const deployedBytecodeHash = ethers.keccak256(deployedBytecode);
        console.log("On chain code hash: " + onChainCodeHash);
        console.log("Deployed code hash: " + deployedBytecodeHash);

        // compare
        if (onChainCodeHash == deployedBytecodeHash) {
            console.log("Code verified successfully!");
        } else {
            console.log("Code verified failed!");
        }
    });

}

// run the script
verify(argv.address, argv.rpc, argv.outJsonPath);