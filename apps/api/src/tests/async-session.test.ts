import test from "node:test";
import assert from "node:assert/strict";
import { AsyncSession, InvalidAsyncSessionError } from "../modules/async-together/domain/AsyncSession.js";
import { GetSessionStateService } from "../modules/async-together/application/GetSessionStateService.js";
import { AsyncSessionMapper } from "../modules/async-together/adapters/persistence/AsyncSessionMapper.js";
import type { AsyncSessionRepository } from "../modules/async-together/application/ports/AsyncSessionRepository.js";

const id = "00000000-0000-4000-8000-000000000001";

test("rich domain entity restores canonical state and validates version", () => {
  const session = AsyncSession.restore(id.toUpperCase(), "RESPONDING", 3n);
  assert.equal(session.id, id);
  assert.equal(session.state, "RESPONDING");
  assert.equal(session.isTerminal, false);
  assert.doesNotThrow(() => session.assertExpectedVersion(3n));
  assert.throws(() => session.assertExpectedVersion(2n), InvalidAsyncSessionError);
  assert.equal(AsyncSession.restore(id, "COMPLETED", 4n).isTerminal, true);
  assert.equal(AsyncSession.restore(id, "EXPIRED", 4n).isTerminal, true);
});

test("domain rejects malformed persisted states and negative version", () => {
  assert.throws(() => AsyncSession.restore("bad", "RESPONDING", 0n), InvalidAsyncSessionError);
  assert.throws(() => AsyncSession.restore(id, "UNEXPECTED", 0n), InvalidAsyncSessionError);
  assert.throws(() => AsyncSession.restore(id, "WAITING", -1n), InvalidAsyncSessionError);
});

test("persistence mapper reconstructs entity without leaking Prisma types", () => {
  const session = AsyncSessionMapper.toDomain({
    id,
    state: "WAITING",
    resourceVersion: 5n,
  });
  assert.equal(session.resourceVersion, 5n);
  assert.equal(session.state, "WAITING");
});

test("application service uses repository interface and constructor injection", async () => {
  const expected = AsyncSession.restore(id, "INITIATING", 1n);
  const fakeRepository: AsyncSessionRepository = {
    async findById(requestedId) {
      return requestedId === id ? expected : null;
    },
  };
  const service = new GetSessionStateService(fakeRepository);
  assert.strictEqual(await service.execute(id), expected);
  assert.equal(await service.execute("00000000-0000-4000-8000-000000000002"), null);
});
