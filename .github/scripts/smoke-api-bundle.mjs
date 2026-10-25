// Smoke test a compiled, production-dependency Fastify artifact with no database secrets.
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import net from "node:net";
import path from "node:path";

const bundlePath = path.resolve(process.argv[2] ?? "apps/api");
const entry = path.join(bundlePath, "dist", "main.js");
assert.ok(existsSync(entry), `Compiled API entry missing: ${entry}`);

const server = net.createServer();
await new Promise((resolve, reject) => {
  server.once("error", reject);
  server.listen(0, "127.0.0.1", resolve);
});
const port = server.address().port;
await new Promise((resolve) => server.close(resolve));

const child = spawn(process.execPath, [entry], {
  cwd: bundlePath,
  env: { ...process.env, HOST: "127.0.0.1", PORT: String(port), DATABASE_URL: "" },
  stdio: "ignore",
});
const url = `http://127.0.0.1:${port}`;

try {
  let alive = false;
  for (let attempt = 0; attempt < 40; attempt++) {
    if (child.exitCode !== null) throw new Error("Fastify process exited before becoming ready");
    try {
      const response = await fetch(`${url}/health/live`, {
        signal: AbortSignal.timeout(1500),
      });
      if (response.status === 200) {
        alive = true;
        break;
      }
    } catch {
      // Process may still be starting up.
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  assert.ok(alive, "Fastify liveness endpoint never became available");

  const readiness = await fetch(`${url}/health/ready`);
  assert.equal(readiness.status, 503, "Database-less artifact must fail readiness");

  const privateRoute = await fetch(`${url}/api/v1/async-sessions/00000000-0000-4000-8000-000000000001`);
  assert.equal(privateRoute.status, 404, "Protected API must remain unpublished");

  console.log("Built API smoke passed: live=200, ready(no DB)=503, private route=404");
} finally {
  child.kill();
}