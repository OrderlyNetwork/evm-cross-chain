import * as readline from 'readline';

interface PromptOptions {
  /** Default value to use if no input is provided */
  defaultValue?: string;
  /** If true, use default value without prompting */
  nonInteractive?: boolean;
}

/**
 * Prompts user for input and parses it to the specified type
 * @param promptText Text to display to the user
 * @param type The desired type to parse the input to ('string' | 'number' | 'boolean')
 * @param options Configuration options for the prompt
 * @returns Promise with the parsed value of type T
 */
export async function promptUser<T extends string | number | boolean>(
  promptText: string,
  type: 'string' | 'number' | 'boolean',
  options: PromptOptions = {}
): Promise<T> {
  // throw error if type is not supported
  if (type !== 'string' && type !== 'number' && type !== 'boolean') {
    throw new Error(`Unsupported type: ${type}`);
  }

  const { defaultValue, nonInteractive = false } = options;

  // In non-interactive mode, use default value or throw error
  if (nonInteractive) {
    return true as T;
  }

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  try {
    let promptString = `${promptText}`;
    if (defaultValue !== undefined) {
      promptString += ` (default: ${defaultValue})`;
    }
    promptString += ': ';

    const answer = await new Promise<string>((resolve) => {
      rl.question(promptString, (answer) => {
        resolve(answer || defaultValue || '');
      });
    });

    return parseValue<T>(answer, type);
  } finally {
    rl.close();
  }
}

function parseValue<T extends string | number | boolean>(
  value: string,
  type: 'string' | 'number' | 'boolean'
): T {
  switch (type) {
    case 'string':
      return value as T;
    case 'number':
      const num = Number(value);
      if (isNaN(num)) {
        throw new Error('Invalid number input');
      }
      return num as T;
    case 'boolean':
      const normalized = value.toLowerCase().trim();
      if (['true', 'yes', '1', 'y'].includes(normalized)) {
        return true as T;
      }
      if (['false', 'no', '0', 'n'].includes(normalized)) {
        return false as T;
      }
      throw new Error('Invalid boolean input');
    default:
      throw new Error(`Unsupported type: ${type}`);
  }
}