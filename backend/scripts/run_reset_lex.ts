import axios from 'axios'; // Dummy import to ensure module resolution? No.
import { DataSource } from 'typeorm';
import * as fs from 'fs';
import * as path from 'path';
import dataSource from '../ormconfig';

async function run() {
  console.log('Initializing DataSource...');
  try {
    await dataSource.initialize();
    console.log('DataSource initialized.');

    const sqlPath = path.join(__dirname, 'reset_dec25_lex.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    // Split by semicolon? OR just run the whole thing? typeorm query running multiple statements might depend on driver.
    // Postgres usually supports multiple statements if passed as one string?
    // Safest is to split.

    console.log('Reading SQL from:', sqlPath);

    // Simple split by ; and newline
    // But the file has comments.
    // Let's try running as single query first. If it fails, I'll split.

    const statements = sql
      .split(';')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);

    for (const statement of statements) {
      console.log('Executing:', statement.substring(0, 50) + '...');
      const result = await dataSource.query(statement);
      console.log('Result:', result);
    }

    console.log('Done.');
  } catch (err) {
    console.error('Error:', err);
  } finally {
    if (dataSource.isInitialized) {
      await dataSource.destroy();
    }
  }
}

run();
