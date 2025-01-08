import * as fs from 'fs/promises';
import { promptUser } from './command_prompt';

interface JsonWriterOptions {
  /** If true, will not prompt for confirmation on updates */
  force?: boolean;
}

/**
 * Updates or adds a value in a JSON file
 * @param filePath Path to the JSON file
 * @param key Key to update or add (supports dot notation e.g., '.parent.child' or 'parent.child')
 * @param value Value to set
 * @param options Configuration options
 */
export async function updateJson(
  filePath: string,
  key: string,
  value: any,
  options: JsonWriterOptions = {}
): Promise<void> {
  const { force = false } = options;
  
  // Read existing JSON file or create new object if file doesn't exist
  let data: any = {};
  try {
    const content = await fs.readFile(filePath, 'utf8');
    data = JSON.parse(content);
  } catch (error: any) {
    if (error.code !== 'ENOENT') {
      throw error;
    }
  }

  // Handle nested keys using dot notation
  // Remove leading dot if present and split remaining path
  const keys = key.startsWith('.') ? key.slice(1).split('.') : key.split('.');
  let current = data;
  const lastKey = keys.pop()!;
  
  // Create nested objects if they don't exist (like mkdir -p)
  for (const k of keys) {
    if (!(k in current)) {
      current[k] = {};
    } else if (typeof current[k] !== 'object' || current[k] === null) {
      // If the current key exists but is not an object, convert it to an object
      current[k] = {};
    }
    current = current[k];
  }

  // Check if we're updating an existing value
  const exists = lastKey in current;
  const oldValue = exists ? current[lastKey] : null;
  
  if (exists && !(options.force ?? await promptUser<boolean>(
    `Value for '${key}' already exists (${JSON.stringify(oldValue)}). Update?`,
    'boolean',
      { defaultValue: 'false' }
    ))) {
    return;
  }

  // Update the value
  current[lastKey] = value;

  // Write back to file with pretty formatting
  await fs.writeFile(filePath, JSON.stringify(data, null, 2));
}
