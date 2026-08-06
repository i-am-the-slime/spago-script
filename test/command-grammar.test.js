import { afterAll, describe, expect, setDefaultTimeout, test } from "bun:test";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

setDefaultTimeout(120_000);
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const runner = path.join(root, "bin", "spago-script.js");
const fixtureDir = await fs.mkdtemp(path.join(os.tmpdir(), "spago-script-grammar-test-"));
const cacheRoot = path.join(fixtureDir, "cache");

async function runFixture(name, source) {
  const script = path.join(fixtureDir, `${name}.purs`);
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

function expectCompilerError(result, message) {
  expect(result.exitCode).not.toBe(0);
  expect(result.stderr).toContain(message);
}

afterAll(async () => {
  await fs.rm(fixtureDir, { force: true, recursive: true });
});

describe("typed command grammars", () => {
  test("accept valid option operands and positional arguments", async () => {
    const result = await runFixture("valid", `main = run do
  when false do
    void $ head @"-n $count $file" { count: 2, file: "names.txt" }
    cp @"$from $to" { from: "a.txt", to: "b.txt" }
`);

    expect(result).toEqual({ exitCode: 0, stdout: "", stderr: "" });
  });

  test("reject an option operand with the wrong semantic type", async () => {
    const result = await runFixture("wrong-option-type", `main = run do
  void $ head @"-n $count $file" { count: true, file: "names.txt" }
`);

    expectCompilerError(result, "head option -n expects Int");
  });

  test("reject the wrong number of positional arguments", async () => {
    const result = await runFixture("wrong-arity", `main = run do
  cp @"$only" { only: "a.txt" }
`);

    expectCompilerError(result, "cp expects SOURCE... DEST");
  });

  test("reject invalid options", async () => {
    const result = await runFixture("invalid-option", `main = run do
  void $ head @"-Z $file" { file: "names.txt" }
`);

    expectCompilerError(result, "Unknown head option: -Z");
  });

  test("preserve argv boundaries for typed placeholders", async () => {
    await fs.writeFile(path.join(fixtureDir, "names with spaces.txt"), "Ada\nGrace\n");
    const result = await runFixture("cat", `main = run do
  contents <- cat @"$file" { file: "names with spaces.txt" }
  sameContents <- cat_ @"'names with spaces.txt'"
  when (sameContents /= contents) $ log "quoted template mismatch"
  matched <- cat @"$file" { file: "names with spaces.txt" }
    |> typedCommand @GrepGrammarDefinition @"$pattern" { pattern: "Grace" }
  log matched
`);

    expect(result).toEqual({ exitCode: 0, stdout: "Grace\n", stderr: "" });
  });
});
