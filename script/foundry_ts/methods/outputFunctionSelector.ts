import * as ethers from "ethers";
import { checkArgs } from "../helper";
import { addOperation } from "../utils/config";
import * as fs from "fs";

const method_name = "outputFunctionSelector";

function outputFunctionSelectorWithArgv(argv: any) {
    const required_flags = ["abiPath"];
    checkArgs(method_name, argv, required_flags);
    outputFunctionSelector(argv.abiPath);
}

// Function to generate ABI encoded function signatures
function outputFunctionSelector(abiPath: string): void {
    // Read ABI from the file
    const rawAbi = fs.readFileSync(abiPath, "utf8");
    let abi = JSON.parse(rawAbi);

    // if abi is not an array, read the 'abi' field
    if (!Array.isArray(abi)) {
        abi = abi.abi;
    }
  
    // Filter out the functions from the ABI
    const functions = abi.filter((item: any) => item.type === "function");

    const funcInterfaces = new ethers.Interface(functions);
  
    // For each function, calculate the selector of the function
    functions.map((func: any) => {
      // print
      console.log(func.name, funcInterfaces.getFunction(func.name)?.selector);
    });
}

addOperation(method_name, outputFunctionSelectorWithArgv);