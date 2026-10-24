import type { FastifyInstance } from "fastify";
import type { HealthController } from "./HealthController.js";

const responseSchema = {
  type: "object",
  additionalProperties: false,
  required: ["status"],
  properties: {
    status: { type: "string", enum: ["ok", "unavailable"] },
  },
} as const;

export class HealthRoutes {
  constructor(private readonly controller: HealthController) {}

  register(app: FastifyInstance): void {
    app.get("/health/live", { schema: { response: { 200: responseSchema } } }, this.controller.live);
    app.get(
      "/health/ready",
      { schema: { response: { 200: responseSchema, 503: responseSchema } } },
      this.controller.ready,
    );
  }
}
