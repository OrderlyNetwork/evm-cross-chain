import * as fs from 'fs/promises';
import { promptUser } from './command_prompt';

type PromptOptions = {
  force?: boolean;
};

/**
 * Updates or adds a value in an ENV file
 * @param filePath Path to the .env file
 * @param key Environment variable name
 * @param value Value to set (will be converted to string)
 */
export async function updateEnv(
  filePath: string,
  key: string,
  value: any,
  options: PromptOptions = {}
): Promise<void> {
  // Validate key format
  if (!/^[A-Z][A-Z0-9_]*$/.test(key)) {
    throw new Error('Environment variable names must be uppercase and start with a letter');
  }

  // Read existing .env file or create new content if file doesn't exist
  let content = '';
  try {
    content = await fs.readFile(filePath, 'utf8');
  } catch (error: any) {
    if (error.code !== 'ENOENT') {
      throw error;
    }
  }

  // Convert value to string and escape special characters
  const stringValue = String(value)
    .replace(/\\/g, '\\\\')  // Escape backslashes first
    .replace(/\n/g, '\\n')
    .replace(/\r/g, '\\r')
    .replace(/"/g, '\\"');   // Escape quotes

  // Create the new entry
  const newEntry = `${key}="${stringValue}"`;

  // Split content into lines and filter out empty lines
  const lines = content.split('\n').filter(line => line.trim());

  // Find existing entry
  const keyPrefix = `${key}=`;
  const existingIndex = lines.findIndex(line => 
    line.trim().startsWith(keyPrefix)
  );

  if (existingIndex >= 0) {
    const shouldUpdate = options.force ?? await promptUser<boolean>(
      `Value for '${key}' already exists (${lines[existingIndex]}). Update?`,
      'boolean',
      { defaultValue: 'false' }
    );
    if (!shouldUpdate) {
      return;
    }
    // Update existing entry
    lines[existingIndex] = newEntry;
  } else {
    // Add new entry
    lines.push(newEntry);
  }

  // Write back to file with a trailing newline
  await fs.writeFile(filePath, lines.join('\n') + '\n');
}
