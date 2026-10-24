import type { PrismaDatabase } from "../../platform/database/PrismaDatabase.js";
import { GetSessionStateService } from "./application/GetSessionStateService.js";
import { PrismaAsyncSessionRepository } from "./adapters/persistence/PrismaAsyncSessionRepository.js";

/** Manual composition root: core only knows repository interface. */
export class AsyncTogetherModule {
  public readonly getSessionState: GetSessionStateService;

  constructor(database: PrismaDatabase) {
    const repository = new PrismaAsyncSessionRepository(database.client);
    this.getSessionState = new GetSessionStateService(repository);
  }
}
