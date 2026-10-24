import test from "node:test";
import assert from "node:assert/strict";
import { EnvironmentConfig } from "../platform/config/EnvironmentConfig.js";

test("safe loopback host and default port", () => {
  const config = EnvironmentConfig.fromEnvironment({});
  assert.equal(config.host, "127.0.0.1");
  assert.equal(config.port, 3000);
});

test("invalid port is rejected at startup", () => {
  for (const port of ["-1", "65536", "abc", "1.5"]) {
    assert.throws(
      () => EnvironmentConfig.fromEnvironment({ PORT: port }),
      /PORT must be an integer/,
    );
  }
});
