import type { ReadinessProbe } from "./ports/ReadinessProbe.js";

/** Operational use case; a failed dependency must not be advertised as ready. */
export class CheckReadinessService {
  constructor(private readonly probe: ReadinessProbe) {}

  async execute(): Promise<boolean> {
    try {
      return await this.probe.check();
    } catch {
      return false;
    }
  }
}
