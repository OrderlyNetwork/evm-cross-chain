import { updateJson } from '../json_writer';
import { promptUser } from '../command_prompt';
import * as fs from 'fs/promises';

jest.mock('fs/promises');
jest.mock('../command_prompt');

describe('updateJson', () => {
  const mockFs = fs as jest.Mocked<typeof fs>;
  const mockPromptUser = promptUser as jest.MockedFunction<typeof promptUser>;

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should create new JSON file with value', async () => {
    mockFs.readFile.mockRejectedValueOnce({ code: 'ENOENT' });

    await updateJson('test.json', 'testKey', 'testValue');

    expect(mockFs.writeFile).toHaveBeenCalledWith(
      'test.json',
      JSON.stringify({ testKey: 'testValue' }, null, 2)
    );
  });

  it('should update existing value with force option', async () => {
    mockFs.readFile.mockResolvedValueOnce(JSON.stringify({ testKey: 'oldValue' }));

    await updateJson('test.json', 'testKey', 'newValue', { force: true });

    expect(mockFs.writeFile).toHaveBeenCalledWith(
      'test.json',
      JSON.stringify({ testKey: 'newValue' }, null, 2)
    );
  });

  it('should handle nested keys', async () => {
    mockFs.readFile.mockResolvedValueOnce('{}');

    await updateJson('test.json', 'parent.child.key', 'value', { force: true });

    expect(mockFs.writeFile).toHaveBeenCalledWith(
      'test.json',
      JSON.stringify({ parent: { child: { key: 'value' } } }, null, 2)
    );
  });

  it('should prompt for confirmation when updating existing value', async () => {
    mockFs.readFile.mockResolvedValueOnce(JSON.stringify({ key: 'oldValue' }));
    mockPromptUser.mockResolvedValueOnce(true);

    await updateJson('test.json', 'key', 'newValue');

    expect(mockPromptUser).toHaveBeenCalled();
    expect(mockFs.writeFile).toHaveBeenCalledWith(
      'test.json',
      JSON.stringify({ key: 'newValue' }, null, 2)
    );
  });

  it('should not update when user declines', async () => {
    mockFs.readFile.mockResolvedValueOnce(JSON.stringify({ key: 'oldValue' }));
    mockPromptUser.mockResolvedValueOnce(false);

    await updateJson('test.json', 'key', 'newValue');

    expect(mockPromptUser).toHaveBeenCalled();
    expect(mockFs.writeFile).not.toHaveBeenCalled();
  });

  it('should handle keys starting with a dot', async () => {
    mockFs.readFile.mockResolvedValueOnce('{}');

    await updateJson('test.json', '.key1.key2.key3', 'value', { force: true });

    expect(mockFs.writeFile).toHaveBeenCalledWith(
      'test.json',
      JSON.stringify({ key1: { key2: { key3: 'value' } } }, null, 2)
    );
  });

  it('should create nested structure when intermediate keys dont exist', async () => {
    mockFs.readFile.mockResolvedValueOnce('{}');

    await updateJson('test.json', '.deeply.nested.key', 'value', { force: true });

    expect(mockFs.writeFile).toHaveBeenCalledWith(
      'test.json',
      JSON.stringify({ deeply: { nested: { key: 'value' } } }, null, 2)
    );
  });

  it('should handle updating nested keys when some parents exist', async () => {
    mockFs.readFile.mockResolvedValueOnce(JSON.stringify({
      existing: {
        parent: 'value'
      }
    }));

    await updateJson('test.json', '.existing.parent.newChild', 'value', { force: true });

    expect(mockFs.writeFile).toHaveBeenCalledWith(
      'test.json',
      JSON.stringify({
        existing: {
          parent: {
            newChild: 'value'
          }
        }
      }, null, 2)
    );
  });

  it('should convert non-object values to objects when needed', async () => {
    mockFs.readFile.mockResolvedValueOnce(JSON.stringify({
      key: 'string value'
    }));

    await updateJson('test.json', '.key.nested', 'new value', { force: true });

    expect(mockFs.writeFile).toHaveBeenCalledWith(
      'test.json',
      JSON.stringify({
        key: {
          nested: 'new value'
        }
      }, null, 2)
    );
  });
}); 