import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export function loadJsonFile(relativePath) {
  const fullPath = resolve(__dirname, '../../../..', relativePath);
  const rawData = readFileSync(fullPath, 'utf8');
  return JSON.parse(rawData);
}
