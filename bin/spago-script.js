#!/usr/bin/env bun

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

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
const source = stripShebang(fs.readFileSync(scriptPath, "utf8"));
const parsedModule = source.match(/^\s*module\s+([A-Z][\w]*(?:\.[A-Z][\w]*)*)\s+where\b/m);
const mainModule = parsedModule ? parsedModule[1] : "Main";
const wrappedSource = parsedModule ? source : wrapScript(source);

const workdir = fs.mkdtempSync(path.join(os.tmpdir(), "spago-script-"));
const scriptModulePath = path.join(workdir, "src", `${mainModule.replaceAll(".", path.sep)}.purs`);

copySkeleton(workdir);
fs.mkdirSync(path.dirname(scriptModulePath), { recursive: true });
fs.writeFileSync(scriptModulePath, wrappedSource);

const build = spawnSync("spago", [
  "build",
  "--offline",
  "--quiet",
  "--censor-stats"
], {
  cwd: workdir,
  env: process.env,
  encoding: "utf8",
  stdio: "pipe"
});

if (build.status !== 0) {
  process.stdout.write(build.stdout ?? "");
  process.stderr.write(build.stderr ?? "");
  process.exit(build.status ?? 1);
}

const runnerPath = path.join(workdir, "run.js");
const mainPath = path.join(workdir, "output", mainModule, "index.js");
fs.writeFileSync(runnerPath, `import { main } from ${JSON.stringify(pathToFileURL(mainPath).href)};\nmain();\n`);

const result = spawnSync("bun", [ runnerPath, ...scriptArgs ], {
  cwd: process.cwd(),
  env: process.env,
  stdio: "inherit"
});

process.exit(result.status ?? 1);

function stripShebang(source) {
  return source.startsWith("#!") ? source.replace(/^.*(?:\r?\n|$)/, "") : source;
}

function wrapScript(source) {
  const annotation = /^\s*main\s*::/m.test(source) ? "" : "main :: Effect Unit\n";
  return `module Main where\n\nimport Script.Prelude\n\n${annotation}${source}`;
}

function ensureCache() {
  const stamp = path.join(cacheDir, ".stamp");
  const expectedStamp = cacheStamp();
  if (cacheIsFresh(stamp, expectedStamp)) return;

  fs.rmSync(cacheDir, { force: true, recursive: true });
  fs.mkdirSync(cacheDir, { recursive: true });
  copyProjectFiles(cacheDir);
  run("spago", cacheBuildArgs(), { cwd: cacheDir });
  fs.writeFileSync(stamp, expectedStamp);
}

function copySkeleton(workdir) {
  ensureCache();
  copyProjectFiles(workdir);
  linkPackages(workdir);
  fs.symlinkSync(path.join(cacheDir, "output"), path.join(workdir, "output"), "dir");
}

function cacheIsFresh(stamp, expectedStamp) {
  return fs.existsSync(stamp)
    && fs.readFileSync(stamp, "utf8") === expectedStamp
    && fs.existsSync(path.join(cacheDir, "output"))
    && fs.existsSync(path.join(cacheDir, "output", "cache-db.json"));
}

function copyProjectFiles(directory) {
  fs.copyFileSync(path.join(root, "spago.yaml"), path.join(directory, "spago.yaml"));
  fs.copyFileSync(path.join(root, "spago.lock"), path.join(directory, "spago.lock"));
  fs.mkdirSync(path.join(directory, "src", "Script"), { recursive: true });
  fs.copyFileSync(path.join(root, "src", "Script", "Prelude.purs"), path.join(directory, "src", "Script", "Prelude.purs"));
  copyIfExists(path.join(root, "src", "Script", "Prelude.js"), path.join(directory, "src", "Script", "Prelude.js"));
}

function linkPackages(directory) {
  const packages = packageStore();
  const tempPackages = path.join(directory, ".spago");
  if (packages && packages !== tempPackages && !fs.existsSync(tempPackages)) {
    fs.symlinkSync(packages, tempPackages, "dir");
  }
}

function packageStore() {
  const rootPackages = path.join(root, ".spago");
  const cachePackages = path.join(cacheDir, ".spago");
  if (fs.existsSync(rootPackages)) return rootPackages;
  if (fs.existsSync(cachePackages)) return cachePackages;
  return null;
}

function cacheBuildArgs() {
  const args = [ "build", "--quiet", "--censor-stats" ];
  return packageStore() ? [ "build", "--offline", "--quiet", "--censor-stats" ] : args;
}

function cacheStamp() {
  return [
    fs.readFileSync(path.join(root, "spago.yaml"), "utf8"),
    fs.readFileSync(path.join(root, "spago.lock"), "utf8"),
    fs.readFileSync(path.join(root, "src", "Script", "Prelude.purs"), "utf8"),
    readIfExists(path.join(root, "src", "Script", "Prelude.js"))
  ].join("\n--- spago-script cache boundary ---\n");
}

function copyIfExists(from, to) {
  if (fs.existsSync(from)) fs.copyFileSync(from, to);
}

function readIfExists(file) {
  return fs.existsSync(file) ? fs.readFileSync(file, "utf8") : "";
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
