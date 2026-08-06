import { afterAll, expect, test } from "bun:test";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const runner = path.join(root, "bin", "spago-script.js");
const fixtureDir = await fs.mkdtemp(path.join(os.tmpdir(), "spago-script-cli-test-"));
const cacheRoot = path.join(fixtureDir, "cache");
const initialWorkdirs = new Set(await workdirs());

async function runScript(name, source) {
  const script = path.join(fixtureDir, name);
  await fs.writeFile(script, source);

  const process = Bun.spawn([runner, script], {
    cwd: fixtureDir,
    env: { ...Bun.env, XDG_CACHE_HOME: cacheRoot },
    stdout: "pipe",
    stderr: "pipe",
  });
  const [exitCode, stdout, stderr] = await Promise.all([
    process.exited,
    new Response(process.stdout).text(),
    new Response(process.stderr).text(),
  ]);

  return { exitCode, stdout, stderr };
}

async function workdirs() {
  return (await fs.readdir(os.tmpdir()))
    .filter((entry) => entry.startsWith("spago-script-"))
    .sort();
}

async function newWorkdirs() {
  return (await workdirs()).filter((entry) => !initialWorkdirs.has(entry));
}

afterAll(async () => {
  await fs.rm(fixtureDir, { force: true, recursive: true });
  await Promise.all((await newWorkdirs()).map((entry) =>
    fs.rm(path.join(os.tmpdir(), entry), { force: true, recursive: true })
  ));
});

test("concurrent scripts use isolated output and clean up workdirs", async () => {
  const mismatches = [];

  for (let round = 0; round < 10; round += 1) {
    const expectedA = `A-${round}\n`;
    const expectedB = `B-${round}\n`;
    const [a, b] = await Promise.all([
      runScript(`a-${round}.purs`, `main = run do\n  log "A-${round}"\n`),
      runScript(`b-${round}.purs`, `main = run do\n  log "B-${round}"\n`),
    ]);

    if (a.exitCode !== 0 || a.stdout !== expectedA) mismatches.push({ expected: expectedA, result: a });
    if (b.exitCode !== 0 || b.stdout !== expectedB) mismatches.push({ expected: expectedB, result: b });
  }

  const failedBuild = await runScript("invalid.purs", "main = this does not compile\n");

  expect({
    mismatches,
    failedBuildExitedNonZero: failedBuild.exitCode !== 0,
    leakedWorkdirs: await newWorkdirs(),
  }).toEqual({
    mismatches: [],
    failedBuildExitedNonZero: true,
    leakedWorkdirs: [],
  });
}, 60_000);
