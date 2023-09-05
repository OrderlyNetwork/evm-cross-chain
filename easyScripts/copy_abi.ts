import * as fs from 'fs';
import * as path from 'path';

function extractAbi(inputPath: string, outputPath: string): void {
  // Read the input JSON file
  const rawData = fs.readFileSync(inputPath, 'utf8');
  const jsonData = JSON.parse(rawData);
  
  // Extract the value of the key "abi"
  const abiData = jsonData['abi'];
  if (abiData === undefined) {
    console.error("The key 'abi' does not exist in the input JSON file.");
    return;
  }

  // Save the extracted value to another JSON file
  fs.writeFileSync(outputPath, JSON.stringify(abiData, null, 2));
  console.log(`Successfully saved ABI data to ${outputPath}`);
}

// Read file paths from command-line arguments
const args = process.argv.slice(2); // The first two elements are the node executable and script path
if (args.length !== 1) {
  console.error('Usage: node extract-abi.js <input JSON file path> ');
  process.exit(1);
}

const inputPath = args[0];
// get the input file name
const inputFileName = path.basename(inputPath);
// get the output file name
// put under abi folder
const outputPath = path.join('./abi', inputFileName);

// logging
console.log(`Extracting ABI data from ${inputPath}`);
console.log(`Saving ABI data to ${outputPath}`);

extractAbi(inputPath, outputPath);
