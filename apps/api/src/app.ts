import type { ReadinessProbe } from "./modules/health/application/ports/ReadinessProbe.js";
import { FastifyApplication } from "./bootstrap/FastifyApplication.js";

export function createApp(readinessProbe?: ReadinessProbe) {
  return new FastifyApplication(readinessProbe).build();
}
