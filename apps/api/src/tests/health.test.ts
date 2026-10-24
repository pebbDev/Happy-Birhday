import test from "node:test";
import assert from "node:assert/strict";
import { createApp } from "../app.js";

test("Fastify liveness endpoint responds via class controller", async () => {
  const app = createApp();
  try {
    const response = await app.inject({ method: "GET", url: "/health/live" });
    assert.equal(response.statusCode, 200);
    assert.deepEqual(response.json(), { status: "ok" });
    assert.equal(response.headers["content-type"], "application/json; charset=utf-8");
  } finally {
    await app.close();
  }
});

test("Fastify does not expose protected domain endpoints prematurely", async () => {
  const app = createApp();
  try {
    const response = await app.inject({
      method: "GET",
      url: "/api/v1/async-sessions/00000000-0000-4000-8000-000000000001",
    });
    assert.equal(response.statusCode, 404);
  } finally {
    await app.close();
  }
});
