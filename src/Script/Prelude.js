import childProcess from "node:child_process";
import fs from "node:fs";
import process from "node:process";

const nonCanceler = (_error, _onError, onSuccess) => onSuccess(undefined);

const nodeAff = action => (onError, onSuccess) => {
  action((error, value) => {
    if (error) {
      onError(error);
    } else {
      onSuccess(value);
    }
  });

  return nonCanceler;
};

const ignoreMissing = callback => error => {
  if (error && error.code !== "ENOENT") {
    callback(error);
  } else {
    callback(null, undefined);
  }
};

export const argvImpl = () => process.argv.slice(2);

export const cwdImpl = () => process.cwd();

export const envImpl = name => () => process.env[name] ?? null;

export const exitImpl = code => () => process.exit(code);

export const readTextFileImpl = filePath => nodeAff(callback => {
  fs.readFile(filePath, "utf8", callback);
});

export const writeTextFileImpl = filePath => contents => nodeAff(callback => {
  fs.writeFile(filePath, contents, "utf8", callback);
});

export const appendTextFileImpl = filePath => contents => nodeAff(callback => {
  fs.appendFile(filePath, contents, "utf8", callback);
});

export const fileExistsImpl = filePath => nodeAff(callback => {
  fs.stat(filePath, (error, stat) => {
    if (error && error.code === "ENOENT") {
      callback(null, false);
    } else if (error) {
      callback(error);
    } else {
      callback(null, stat.isFile());
    }
  });
});

export const directoryExistsImpl = filePath => nodeAff(callback => {
  fs.stat(filePath, (error, stat) => {
    if (error && error.code === "ENOENT") {
      callback(null, false);
    } else if (error) {
      callback(error);
    } else {
      callback(null, stat.isDirectory());
    }
  });
});

export const mkdirpImpl = directory => nodeAff(callback => {
  fs.mkdir(directory, { recursive: true }, error => callback(error, undefined));
});

export const removeFileImpl = filePath => nodeAff(callback => {
  fs.rm(filePath, { force: true }, ignoreMissing(callback));
});

export const removeDirImpl = directory => nodeAff(callback => {
  fs.rm(directory, { force: true, recursive: true }, ignoreMissing(callback));
});

export const listDirImpl = directory => nodeAff(callback => {
  fs.readdir(directory, callback);
});

export const execImpl = command => commandArgs => nodeAff(callback => {
  childProcess.execFile(command, commandArgs, { encoding: "utf8", maxBuffer: 1024 * 1024 * 10 }, (error, stdout, stderr) => {
    if (error && typeof error.code !== "number") {
      callback(error);
    } else {
      callback(null, {
        code: error ? error.code : 0,
        stdout,
        stderr
      });
    }
  });
});
