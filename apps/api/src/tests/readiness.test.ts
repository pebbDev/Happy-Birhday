import test from "node:test";
import assert from "node:assert/strict";
import { createApp } from "../app.js";
import type { ReadinessProbe } from "../modules/health/application/ports/ReadinessProbe.js";

test("readiness is 503 when DB dependency isn't configured", async () => {
  const app = createApp();
  try {
    const reply = await app.inject({ method: "GET", url: "/health/ready" });
    assert.equal(reply.statusCode, 503);
    assert.deepEqual(reply.json(), { status: "unavailable" });
  } finally {
    await app.close();
  }
});

test("readiness 200 when dependency is verified", async () => {
  const readiness: ReadinessProbe = { check: async () => true };
  const app = createApp(readiness);
  try {
    const reply = await app.inject({ method: "GET", url: "/health/ready" });
    assert.equal(reply.statusCode, 200);
    assert.deepEqual(reply.json(), { status: "ok" });
  } finally {
    await app.close();
  }
});

test("dependency exceptions fail closed without leaking details", async () => {
  const readiness: ReadinessProbe = { check: async () => { throw new Error("secret connection detail"); } };
  const app = createApp(readiness);
  try {
    const reply = await app.inject({ method: "GET", url: "/health/ready" });
    assert.equal(reply.statusCode, 503);
    assert.deepEqual(reply.json(), { status: "unavailable" });
    assert.equal(reply.body.includes("secret connection detail"), false);
  } finally {
    await app.close();
  }
});
