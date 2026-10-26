import test from "node:test";
import assert from "node:assert/strict";
import { PrismaDatabase } from "../platform/database/PrismaDatabase.js";

const url = "postgresql://postgres.dev:dummy@localhost:6543/postgres?sslmode=require";
const trustedCa = "-----BEGIN CERTIFICATE-----\nZHVtbXk=\n-----END CERTIFICATE-----";

test("Prisma adapter accepts explicit CA configuration without connecting", async () => {
  const database = new PrismaDatabase(url, trustedCa);
  await database.disconnect();
});

test("rejects CA data that is not PEM", () => {
  assert.throws(() => new PrismaDatabase(url, "not a certificate"), /valid PEM certificate/);
});

test("rejects disabling TLS with an explicit trusted CA", () => {
  assert.throws(() => new PrismaDatabase(url.replace("sslmode=require", "sslmode=disable"), trustedCa), /must request TLS/);
});

test("rejects URL parameters that would override configured trusted CA", () => {
  assert.throws(() => new PrismaDatabase(url + "&sslrootcert=other.crt", trustedCa), /must not override/);
});
