#!/usr/bin/env bun

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const bin = fileURLToPath(import.meta.url);
const root = path.resolve(path.dirname(bin), "..");
const cacheRoot = process.env.XDG_CACHE_HOME ?? path.join(os.homedir(), ".cache");
const cacheDir = path.join(cacheRoot, "spago-script-prelude");

const [script, ...scriptArgs] = process.argv.slice(2);

if (!script || script === "--help" || script === "-h") {
  console.log(`Usage: spago-script <script.purs> [args...]

Creates a temporary Spago project with Script.Prelude, a cached package set,
and a warm output directory, then runs the script with Spago.

Scripts without a module header are wrapped as:

  module Main where
  import Script.Prelude

  main :: Effect Unit
  <script contents>
`);
  process.exit(script ? 0 : 1);
}

ensureCache();

const scriptPath = path.resolve(process.cwd(), script);
const source = fs.readFileSync(scriptPath, "utf8");
const parsedModule = source.match(/^\s*module\s+([A-Z][\w]*(?:\.[A-Z][\w]*)*)\s+where\b/m);
const mainModule = parsedModule ? parsedModule[1] : "Main";
const wrappedSource = parsedModule ? source : wrapScript(source);

const workdir = fs.mkdtempSync(path.join(os.tmpdir(), "spago-script-"));
const scriptModulePath = path.join(workdir, "src", `${mainModule.replaceAll(".", path.sep)}.purs`);

copySkeleton(workdir);
fs.mkdirSync(path.dirname(scriptModulePath), { recursive: true });
fs.writeFileSync(scriptModulePath, wrappedSource);

const result = spawnSync("spago", [
  "run",
  "--offline",
  "--quiet",
  "--main",
  mainModule,
  ...scriptArgs
], {
  cwd: workdir,
  env: process.env,
  stdio: "inherit"
});

process.exit(result.status ?? 1);

function wrapScript(source) {
  const annotation = /^\s*main\s*::/m.test(source) ? "" : "main :: Effect Unit\n";
  return `module Main where\n\nimport Script.Prelude\n\n${annotation}${source}`;
}

function ensureCache() {
  const stamp = path.join(cacheDir, ".stamp");
  const expectedStamp = cacheStamp();
  if (fs.existsSync(stamp) && fs.readFileSync(stamp, "utf8") === expectedStamp) return;

  fs.rmSync(cacheDir, { force: true, recursive: true });
  fs.mkdirSync(cacheDir, { recursive: true });
  copyProjectFiles(cacheDir);
  linkPackages(cacheDir);

  run("spago", [ "build", "--offline", "--quiet" ], { cwd: cacheDir, stdio: "inherit" });
  fs.writeFileSync(stamp, expectedStamp);
}

function copySkeleton(workdir) {
  copyProjectFiles(workdir);
  linkPackages(workdir);
  fs.symlinkSync(path.join(cacheDir, "output"), path.join(workdir, "output"), "dir");
}

function copyProjectFiles(directory) {
  fs.copyFileSync(path.join(root, "spago.yaml"), path.join(directory, "spago.yaml"));
  fs.copyFileSync(path.join(root, "spago.lock"), path.join(directory, "spago.lock"));
  fs.mkdirSync(path.join(directory, "src", "Script"), { recursive: true });
  fs.copyFileSync(path.join(root, "src", "Script", "Prelude.purs"), path.join(directory, "src", "Script", "Prelude.purs"));
  fs.copyFileSync(path.join(root, "src", "Script", "Prelude.js"), path.join(directory, "src", "Script", "Prelude.js"));
}

function linkPackages(directory) {
  const cachedPackages = path.join(root, ".spago");
  const tempPackages = path.join(directory, ".spago");
  if (fs.existsSync(cachedPackages) && !fs.existsSync(tempPackages)) {
    fs.symlinkSync(cachedPackages, tempPackages, "dir");
  }
}

function cacheStamp() {
  return [
    fs.readFileSync(path.join(root, "spago.yaml"), "utf8"),
    fs.readFileSync(path.join(root, "spago.lock"), "utf8"),
    fs.readFileSync(path.join(root, "src", "Script", "Prelude.purs"), "utf8"),
    fs.readFileSync(path.join(root, "src", "Script", "Prelude.js"), "utf8")
  ].join("\n--- spago-script cache boundary ---\n");
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: options.cwd,
    env: process.env,
    encoding: "utf8",
    stdio: options.stdio ?? "pipe"
  });

  if (result.status !== 0) {
    if (result.stdout) process.stdout.write(result.stdout);
    if (result.stderr) process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }

  return result;
}
