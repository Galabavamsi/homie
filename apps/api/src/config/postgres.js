import pg from 'pg';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { env } from './env.js';

export const pgPool = env.databaseUrl
  ? new pg.Pool({
      connectionString: env.databaseUrl,
      max: 10,
      idleTimeoutMillis: 30_000,
      connectionTimeoutMillis: 5_000
    })
  : null;

export async function initializePostgres() {
  if (!pgPool) return;
  const migrationUrl = new URL('../db/migrations/001_collaboration.sql', import.meta.url);
  const sql = await readFile(fileURLToPath(migrationUrl), 'utf8');
  await pgPool.query(sql);
}

export async function closePostgres() {
  if (pgPool) await pgPool.end();
}
