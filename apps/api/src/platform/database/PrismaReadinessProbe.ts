import type { PrismaClient } from "../../generated/prisma/client.js";
import type { ReadinessProbe } from "../../modules/health/application/ports/ReadinessProbe.js";

export class PrismaReadinessProbe implements ReadinessProbe {
  constructor(private readonly client: PrismaClient) {}

  async check(): Promise<boolean> {
    const rows = await this.client.$queryRaw<Array<{ ready: number }>>`SELECT 1 AS ready`;
    return rows.length === 1 && rows[0]?.ready === 1;
  }
}
