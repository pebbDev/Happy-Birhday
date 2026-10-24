import { defineConfig } from "prisma/config";

// PostgreSQL SQL migrations remain governed by ../../supabase/migrations/.
// DATABASE_URL is required only for connecting/introspecting; never commit credentials.
export default defineConfig({
  schema: "prisma/schema.prisma",
  datasource: {
    url: process.env.DATABASE_URL ?? "",
  },
});
