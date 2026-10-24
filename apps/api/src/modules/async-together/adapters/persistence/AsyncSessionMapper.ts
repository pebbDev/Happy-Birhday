import { AsyncSession } from "../../domain/AsyncSession.js";

type PersistedSession = {
  id: string;
  state: string;
  resourceVersion: bigint;
};

export class AsyncSessionMapper {
  static toDomain(record: PersistedSession): AsyncSession {
    return AsyncSession.restore(record.id, record.state, record.resourceVersion);
  }
}
