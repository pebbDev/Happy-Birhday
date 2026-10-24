import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "../../generated/prisma/client.js";

/** Node-only infrastructure adapter. No DB connections when not constructed. */
export class PrismaDatabase {
  public readonly client: PrismaClient;

  constructor(connectionString: string) {
    if (!connectionString) {
      throw new Error("DATABASE_URL is required for database-backed services.");
    }
    const adapter = new PrismaPg({
      connectionString,
      max: 2,
      connectionTimeoutMillis: 5000,
    });
    this.client = new PrismaClient({ adapter });
  }

  disconnect(): Promise<void> {
    return this.client.$disconnect();
  }
}
