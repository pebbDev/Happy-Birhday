import test from "node:test";
import assert from "node:assert/strict";
import { readdir, readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { join } from "node:path";

const srcRoot = fileURLToPath(new URL("../", import.meta.url));
const modulesRoot = join(srcRoot, "modules");

async function inspectRecursively(directory: string): Promise<string[]> {
  const files: string[] = [];
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) files.push(...await inspectRecursively(path));
    else if (entry.isFile() && entry.name.endsWith(".ts")) files.push(path);
  }
  return files;
}

test("all module domain/application code stays independent of outer layers", async () => {
  const modules = await readdir(modulesRoot, { withFileTypes: true });
  let scanned = 0;
  for (const module of modules) {
    if (!module.isDirectory()) continue;
    for (const layer of ["domain", "application"]) {
      const directory = join(modulesRoot, module.name, layer);
      const files = await readdir(directory, { withFileTypes: true }).catch((err: NodeJS.ErrnoException) => {
        if (err.code === "ENOENT") return [];
        throw err;
      });
      if (files.length === 0) continue;
      for (const file of await inspectRecursively(directory)) {
        scanned++;
        const source = await readFile(file, "utf8");
        const imports = [...source.matchAll(/\bfrom\s+["']([^"']+)["']/g)].map((x) => x[1] ?? "");
        for (const imported of imports) {
          assert.doesNotMatch(
            imported,
            /(^fastify$|^@prisma\/|^pg$|generated\/prisma|\/adapters\/|\/infrastructure\/|platform\/database)/,
            `${file}: illegal outward import ${imported}`,
          );
        }
      }
    }
  }
  assert.ok(scanned >= 3, "architecture test must exercise business/application source files");
});
