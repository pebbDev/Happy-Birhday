import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "../../generated/prisma/client.js";

/** Node-only infrastructure adapter. No DB connections when not constructed. */
export class PrismaDatabase {
  public readonly client: PrismaClient;

  constructor(connectionString: string, trustedCaPem?: string) {
    if (!connectionString) {
      throw new Error("DATABASE_URL is required for database-backed services.");
    }
    // node-postgres maps sslmode=require to ssl:true (which verifies the CA),
    // but Node does not trust Supabase's private CA out of the box.
    // Supply the dashboard-downloaded CA explicitly; never disable validation.
    const settings = {
      connectionString,
      max: 1, // one DB connection per warm serverless instance
      connectionTimeoutMillis: 5000,
      ...(trustedCaPem?.trim()
        ? {
            ssl: { ca: trustedCaPem, rejectUnauthorized: true },
          }
        : {}),
    };

    if (trustedCaPem?.trim()) {
      if (!trustedCaPem.includes("-----BEGIN CERTIFICATE-----")) {
        throw new Error("SUPABASE_DB_CA_CERT_BASE64 is not a valid PEM certificate.");
      }
      // pg-connection-string overwrites the explicit ssl object if the URI
      // has sslmode/sslcert/sslrootcert/sslkey: strip sslmode only when CA is set.
      const url = new URL(connectionString);
      const sslmode = url.searchParams.get("sslmode");
      if (sslmode && sslmode !== "require" && sslmode !== "verify-full") {
        throw new Error("DATABASE_URL must request TLS.");
      }
      if (["sslcert", "sslkey", "sslrootcert"].some((key) => url.searchParams.has(key))) {
        throw new Error("DATABASE_URL must not override the trusted TLS CA configuration.");
      }
      url.searchParams.delete("sslmode");
      settings.connectionString = url.toString();
    }
    const adapter = new PrismaPg(settings);
    this.client = new PrismaClient({ adapter });
  }

  disconnect(): Promise<void> {
    return this.client.$disconnect();
  }
}
