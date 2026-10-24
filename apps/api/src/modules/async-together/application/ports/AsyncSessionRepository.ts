import type { AsyncSession } from "../../domain/AsyncSession.js";

export interface AsyncSessionRepository {
  findById(id: string): Promise<AsyncSession | null>;
}
