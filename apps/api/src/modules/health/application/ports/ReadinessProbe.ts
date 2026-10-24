/** A readiness probe is infrastructure-dependent, but its contract belongs to the application. */
export interface ReadinessProbe {
  check(): Promise<boolean>;
}
