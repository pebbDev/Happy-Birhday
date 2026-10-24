import type { AsyncSession } from "../domain/AsyncSession.js";
import type { AsyncSessionRepository } from "./ports/AsyncSessionRepository.js";

/**
 * Internal application read service. Deliberately NOT exposed via HTTP yet:
 * protected participant authorization must be migrated and tested first.
 */
export class GetSessionStateService {
  constructor(private readonly repository: AsyncSessionRepository) {}

  execute(id: string): Promise<AsyncSession | null> {
    return this.repository.findById(id);
  }
}
