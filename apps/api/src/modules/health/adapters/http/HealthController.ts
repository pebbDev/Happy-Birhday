import type { FastifyReply, FastifyRequest } from "fastify";
import type { CheckReadinessService } from "../../application/CheckReadinessService.js";

export class HealthController {
  constructor(private readonly readiness: CheckReadinessService) {}

  readonly live = async (_request: FastifyRequest, reply: FastifyReply) => {
    return reply.code(200).send({ status: "ok" });
  };

  readonly ready = async (_request: FastifyRequest, reply: FastifyReply) => {
    const ready = await this.readiness.execute();
    return reply.code(ready ? 200 : 503).send({
      status: ready ? "ok" : "unavailable",
    });
  };
}
