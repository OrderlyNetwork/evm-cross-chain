import fs from 'fs';

/**
 * Error thrown when a JSON path is invalid or the value doesn't exist
 */
export class JsonError extends Error {
  constructor(path: string, message: string) {
    super(`Error accessing path "${path}": ${message}`);
    this.name = 'JsonPathError';
  }
}

/**
 * Reads a value from a JSON object using dot notation
 * @param jsonPath The path to the JSON file
 * @param key The key to read from the JSON file
 * @returns The value at the specified path
 * @throws {JsonError} If the path is invalid or the value doesn't exist
 */
export function readJsonValue(jsonPath: string, key: string): {
  value: any;
  exists: boolean;
} {
  if (!jsonPath) {
    throw new JsonError(jsonPath, 'Path cannot be empty');
  }

  let json: any;

  // check if the jsonPath exists and parse as json
  if (fs.existsSync(jsonPath)) {
    json = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  } else {
    throw new JsonError(jsonPath, 'File does not exist');
  }

  const keys = key.split('.').slice(1);
  let current = json;

  // check if the .key1.key2.key3 exists
  // for example .key1.key2.key3 is json['key1']['key2']['key3']
  for (const key of keys) {
    if (current[key] === undefined) {
      return { value: null, exists: false };
    }
    current = current[key];
  }
  return { value: current, exists: true };
} 