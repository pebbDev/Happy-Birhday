export class EnvironmentConfig {
  private constructor(
    public readonly host: string,
    public readonly port: number,
  ) {}

  static fromEnvironment(
    env: Readonly<Record<string, string | undefined>>,
  ): EnvironmentConfig {
    const host = env.HOST?.trim() || "127.0.0.1";
    const port = Number(env.PORT ?? "3000");
    if (!Number.isSafeInteger(port) || port < 0 || port > 65535) {
      throw new Error("PORT must be an integer between 0 and 65535.");
    }
    return new EnvironmentConfig(host, port);
  }
}
