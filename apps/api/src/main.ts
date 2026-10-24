import { createApp } from "./app.js";
import { ApplicationContainer } from "./bootstrap/ApplicationContainer.js";
import { EnvironmentConfig } from "./platform/config/EnvironmentConfig.js";

const config = EnvironmentConfig.fromEnvironment(process.env);
const container = new ApplicationContainer(process.env);
const app = createApp(container.readinessProbe);
app.addHook("onClose", async () => container.close());

try {
  await app.listen({ port: config.port, host: config.host });
} catch (error) {
  app.log.error(error, "Fastify startup failed");
  await app.close();
  process.exitCode = 1;
}
