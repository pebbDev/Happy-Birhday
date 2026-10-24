import Fastify, { type FastifyInstance } from "fastify";
import { CheckReadinessService } from "../modules/health/application/CheckReadinessService.js";
import type { ReadinessProbe } from "../modules/health/application/ports/ReadinessProbe.js";
import { HealthController } from "../modules/health/adapters/http/HealthController.js";
import { HealthRoutes } from "../modules/health/adapters/http/HealthRoutes.js";

class NotReadyProbe implements ReadinessProbe {
  async check(): Promise<boolean> {
    return false;
  }
}

export class FastifyApplication {
  constructor(private readonly readinessProbe: ReadinessProbe = new NotReadyProbe()) {}

  build(): FastifyInstance {
    const app = Fastify({
      logger: {
        level: "info",
        redact: {
          paths: [
            "req.headers.authorization",
            "req.headers.cookie",
            "req.headers['x-hbd-internal-token']",
            "res.headers['set-cookie']",
          ],
          censor: "[REDACTED]",
        },
      },
    });

    const service = new CheckReadinessService(this.readinessProbe);
    const routes = new HealthRoutes(new HealthController(service));
    // Native Fastify plugin callback is the transport boundary, not a domain object.
    app.register(async (scope) => routes.register(scope));
    return app;
  }
}
