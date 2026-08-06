import { pgPool, initializePostgres } from '../config/postgres.js';
import { MemoryCollaborationRepository } from './MemoryCollaborationRepository.js';
import { PostgresCollaborationRepository } from './PostgresCollaborationRepository.js';

export async function createCollaborationRepository() {
  if (!pgPool) return new MemoryCollaborationRepository();
  await initializePostgres();
  return new PostgresCollaborationRepository(pgPool);
}
