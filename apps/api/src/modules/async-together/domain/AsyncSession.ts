export type AsyncSessionState =
  | "INITIATING"
  | "WAITING"
  | "RESPONDING"
  | "COMPLETED"
  | "EXPIRED";

export class InvalidAsyncSessionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "InvalidAsyncSessionError";
  }
}

/**
 * Read-side domain representation of an AsyncSession aggregate.
 * IMPORTANT: This class does not reimplement the legacy trusted SQL/RPC
 * mutation lifecycle, authorization, or concurrency guarantees.
 */
export class AsyncSession {
  private static readonly knownStates: ReadonlySet<string> = new Set([
    "INITIATING", "WAITING", "RESPONDING", "COMPLETED", "EXPIRED",
  ]);

  private constructor(
    public readonly id: string,
    private readonly currentState: AsyncSessionState,
    public readonly resourceVersion: bigint,
  ) {}

  static restore(
    id: string,
    state: string,
    resourceVersion: bigint,
  ): AsyncSession {
    if (
      !/^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$/i.test(id) ||
      !AsyncSession.knownStates.has(state) ||
      resourceVersion < 0n
    ) {
      throw new InvalidAsyncSessionError("Invalid persisted AsyncSession.");
    }
    return new AsyncSession(
      id.toLowerCase(),
      state as AsyncSessionState,
      resourceVersion,
    );
  }

  get state(): AsyncSessionState {
    return this.currentState;
  }

  get isTerminal(): boolean {
    return this.currentState === "COMPLETED" || this.currentState === "EXPIRED";
  }

  assertExpectedVersion(expectedVersion: bigint): void {
    if (expectedVersion !== this.resourceVersion) {
      throw new InvalidAsyncSessionError("AsyncSession version is stale.");
    }
  }
}
