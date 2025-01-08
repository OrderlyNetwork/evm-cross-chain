import { promptUser } from '../command_prompt';
import * as readline from 'readline';

jest.mock('readline', () => ({
  createInterface: jest.fn(),
}));

describe('promptUser', () => {
  let mockQuestion: jest.Mock;
  let mockClose: jest.Mock;

  beforeEach(() => {
    mockQuestion = jest.fn();
    mockClose = jest.fn();
    (readline.createInterface as jest.Mock).mockReturnValue({
      question: mockQuestion,
      close: mockClose,
    });
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should correctly parse string input', async () => {
    const testInput = 'test string';
    mockQuestion.mockImplementation((_, callback) => callback(testInput));

    const result = await promptUser<string>('Enter text', 'string');
    expect(result).toBe(testInput);
  });

  it('should correctly parse number input', async () => {
    const testInput = '42';
    mockQuestion.mockImplementation((_, callback) => callback(testInput));

    const result = await promptUser<number>('Enter number', 'number');
    expect(result).toBe(42);
  });

  it('should throw error for invalid number input', async () => {
    mockQuestion.mockImplementation((_, callback) => callback('not a number'));

    await expect(promptUser<number>('Enter number', 'number'))
      .rejects
      .toThrow('Invalid number input');
  });

  it('should correctly parse boolean input - true values', async () => {
    const trueValues = ['true', 'yes', '1', 'y'];

    for (const value of trueValues) {
      mockQuestion.mockImplementation((_, callback) => callback(value));
      const result = await promptUser<boolean>('Enter boolean', 'boolean');
      expect(result).toBe(true);
    }
  });

  it('should correctly parse boolean input - false values', async () => {
    const falseValues = ['false', 'no', '0', 'n'];

    for (const value of falseValues) {
      mockQuestion.mockImplementation((_, callback) => callback(value));
      const result = await promptUser<boolean>('Enter boolean', 'boolean');
      expect(result).toBe(false);
    }
  });

  it('should throw error for invalid boolean input', async () => {
    mockQuestion.mockImplementation((_, callback) => callback('invalid'));

    await expect(promptUser<boolean>('Enter boolean', 'boolean'))
      .rejects
      .toThrow('Invalid boolean input');
  });

  it('should throw error for unsupported type', async () => {
    await expect(promptUser('Test', 'unsupported' as any))
      .rejects
      .toThrow('Unsupported type: unsupported');
  });

  it('should close readline interface after completion', async () => {
    mockQuestion.mockImplementation((_, callback) => callback('test'));

    await promptUser<string>('Test', 'string');
    expect(mockClose).toHaveBeenCalled();
  });

  it('should use default value when no input is provided', async () => {
    mockQuestion.mockImplementation((_, callback) => callback(''));

    const result = await promptUser<string>('Test', 'string', { defaultValue: 'default' });
    expect(result).toBe('default');
  });

}); 