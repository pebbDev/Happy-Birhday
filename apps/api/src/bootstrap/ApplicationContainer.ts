import { AsyncTogetherModule } from "../modules/async-together/AsyncTogetherModule.js";
import type { ReadinessProbe } from "../modules/health/application/ports/ReadinessProbe.js";
import { PrismaDatabase } from "../platform/database/PrismaDatabase.js";
import { PrismaReadinessProbe } from "../platform/database/PrismaReadinessProbe.js";

class UnavailableReadinessProbe implements ReadinessProbe {
  async check(): Promise<boolean> {
    return false;
  }
}

/**
 * Single composition root. A missing DB URL leaves only liveness operational;
 * it does NOT silently enable any private business routes.
 */
export class ApplicationContainer {
  private readonly database: PrismaDatabase | undefined;
  readonly readinessProbe: ReadinessProbe;
  readonly asyncTogether: AsyncTogetherModule | undefined;

  constructor(env: Readonly<Record<string, string | undefined>>) {
    if (env.DATABASE_URL?.trim()) {
      const trustedCaPem = env.SUPABASE_DB_CA_CERT_BASE64?.trim()
        ? Buffer.from(env.SUPABASE_DB_CA_CERT_BASE64, "base64").toString("utf8")
        : undefined;
      this.database = new PrismaDatabase(env.DATABASE_URL, trustedCaPem);
      this.readinessProbe = new PrismaReadinessProbe(this.database.client);
      this.asyncTogether = new AsyncTogetherModule(this.database);
    } else {
      this.readinessProbe = new UnavailableReadinessProbe();
      this.asyncTogether = undefined;
    }
  }

  async close(): Promise<void> {
    await this.database?.disconnect();
  }
}
