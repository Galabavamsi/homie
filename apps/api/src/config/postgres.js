import pg from 'pg';
import { env } from './env.js';

export const pgPool = env.databaseUrl
  ? new pg.Pool({ connectionString: env.databaseUrl })
  : null;

export async function closePostgres() {
  if (pgPool) await pgPool.end();
}
