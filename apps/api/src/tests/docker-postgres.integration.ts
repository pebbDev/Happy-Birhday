/**
 * Runs only with an isolated Docker PostgreSQL fixture, never hosted Supabase.
 * Intentionally named *.integration.ts so unit-test glob does not execute it.
 */
import assert from "node:assert/strict";
import test from "node:test";
import { createApp } from "../app.js";
import { ApplicationContainer } from "../bootstrap/ApplicationContainer.js";
import { PrismaDatabase } from "../platform/database/PrismaDatabase.js";

function localTestDatabaseUrl(): string {
  const raw = process.env.HBD_TEST_DATABASE_URL;
  assert.ok(raw, "HBD_TEST_DATABASE_URL is required for isolated integration tests");
  const url = new URL(raw);
  // Fail closed on remote URLs, Supabase pools, invalid credentials or TLS overrides.
  assert.equal(url.protocol, "postgresql:", "Only PostgreSQL URLs are permitted");
  assert.equal(url.hostname, "127.0.0.1", "Tests must use loopback, never hosted Supabase");
  assert.equal(url.pathname, "/hbd_test", "Tests must use the disposable hbd_test database");
  assert.equal(url.username, "postgres", "Tests must use the isolated PostgreSQL test user");
  assert.ok(url.port && Number(url.port) > 0, "An explicit test DB port is required");
  assert.ok(url.password, "An isolated test DB password is required");
  assert.equal(url.hash, "", "Fragments are not allowed");
  for (const parameter of ["sslmode", "sslrootcert", "sslcert", "sslkey", "host", "hostaddr", "service"]) {
    assert.equal(url.searchParams.has(parameter), false, `Unsafe test URL parameter: ${parameter}`);
  }
  return raw;
}

test("Docker PostgreSQL: Fastify readiness and Prisma SQL/model mapping", async () => {
  const connectionString = localTestDatabaseUrl();
  const container = new ApplicationContainer({ DATABASE_URL: connectionString });
  const app = createApp(container.readinessProbe);
  app.addHook("onClose", async () => container.close());
  const database = new PrismaDatabase(connectionString);
  try {
    const live = await app.inject({ method: "GET", url: "/health/live" });
    assert.equal(live.statusCode, 200);
    assert.deepEqual(live.json(), { status: "ok" });

    const ready = await app.inject({ method: "GET", url: "/health/ready" });
    assert.equal(ready.statusCode, 200, "Fastify must query PostgreSQL via Prisma");
    assert.deepEqual(ready.json(), { status: "ok" });

    const rows = await database.client.$queryRaw<Array<{ name: string | null }>>`
      SELECT to_regclass('public.async_session')::text AS name
    `;
    assert.equal(rows[0]?.name, "async_session", "Canonical SQL migrations must be applied first");

    const missingRecord = await database.client.asyncSessionRecord.findUnique({
      where: { id: "00000000-0000-4000-8000-000000000001" },
      select: { id: true },
    });
    assert.equal(missingRecord, null, "Prisma table mapping should query successfully without inserting fixtures");
  } finally {
    await app.close();
    await database.disconnect();
  }
});
