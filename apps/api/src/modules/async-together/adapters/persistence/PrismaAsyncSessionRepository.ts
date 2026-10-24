import type { PrismaClient } from "../../../../generated/prisma/client.js";
import type { AsyncSessionRepository } from "../../application/ports/AsyncSessionRepository.js";
import type { AsyncSession } from "../../domain/AsyncSession.js";
import { AsyncSessionMapper } from "./AsyncSessionMapper.js";

export class PrismaAsyncSessionRepository implements AsyncSessionRepository {
  constructor(private readonly client: PrismaClient) {}

  async findById(id: string): Promise<AsyncSession | null> {
    const row = await this.client.asyncSessionRecord.findUnique({
      where: { id },
      select: { id: true, state: true, resourceVersion: true },
    });

    return row ? AsyncSessionMapper.toDomain(row) : null;
  }
}
