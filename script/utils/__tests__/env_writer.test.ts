import { promptUser } from '../command_prompt';
import { updateEnv } from '../env_writer';
import * as fs from 'fs/promises';

jest.mock('fs/promises');
jest.mock('../command_prompt');

describe('updateEnv', () => {
  const mockFs = fs as jest.Mocked<typeof fs>;
  const mockPromptUser = promptUser as jest.MockedFunction<typeof promptUser>;

  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  it('should create new env file with value', async () => {
    mockFs.readFile.mockRejectedValueOnce({ code: 'ENOENT' });

    await updateEnv('.env', 'TEST_KEY', 'test value');

    expect(mockFs.writeFile).toHaveBeenCalledWith(
      '.env',
      'TEST_KEY="test value"\n'
    );
  });

  it('should update existing value', async () => {
    mockFs.readFile.mockResolvedValueOnce('TEST_KEY="old value"\n');
    // mock user input
    mockPromptUser.mockResolvedValueOnce(true);

    await updateEnv('.env', 'TEST_KEY', 'new value');

    expect(mockFs.writeFile).toHaveBeenCalledWith(
      '.env',
      'TEST_KEY="new value"\n'
    );
  });

  it('should add new value to existing file', async () => {
    mockFs.readFile.mockResolvedValueOnce('EXISTING_KEY="value"\n');

    await updateEnv('.env', 'NEW_KEY', 'new value');

    expect(mockFs.writeFile).toHaveBeenCalledWith(
      '.env',
      'EXISTING_KEY="value"\nNEW_KEY="new value"\n'
    );
  });

  it('should escape special characters', async () => {
    mockFs.readFile.mockRejectedValueOnce({ code: 'ENOENT' });

    await updateEnv('.env', 'TEST_KEY', 'value\nwith\nnewlines and "quotes"');

    expect(mockFs.writeFile).toHaveBeenCalledWith(
      '.env',
      'TEST_KEY="value\\nwith\\nnewlines and \\"quotes\\""\n'
    );
  });

  it('should handle empty file', async () => {
    mockFs.readFile.mockResolvedValueOnce('');

    await updateEnv('.env', 'TEST_KEY', 'value');

    expect(mockFs.writeFile).toHaveBeenCalledWith(
      '.env',
      'TEST_KEY="value"\n'
    );
  });

  it('should validate environment variable names', async () => {
    await expect(updateEnv('.env', 'invalid-key', 'value'))
      .rejects
      .toThrow('Environment variable names must be uppercase and start with a letter');
  });

  it('should handle multiple empty lines in file', async () => {
    mockFs.readFile.mockResolvedValueOnce('KEY1="value1"\n\n\nKEY2="value2"\n\n');

    await updateEnv('.env', 'TEST_KEY', 'value');

    expect(mockFs.writeFile).toHaveBeenCalledWith(
      '.env',
      'KEY1="value1"\nKEY2="value2"\nTEST_KEY="value"\n'
    );
  });

  it('should convert non-string values to strings', async () => {
    mockFs.readFile.mockRejectedValueOnce({ code: 'ENOENT' });

    await updateEnv('.env', 'NUMBER_KEY', 123);

    expect(mockFs.writeFile).toHaveBeenCalledWith(
      '.env',
      'NUMBER_KEY="123"\n'
    );
  });
}); 