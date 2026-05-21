#!/usr/bin/env node

/**
 * build-installer.js — Build the NSIS installer for Markdown Viewer.
 *
 * This script:
 *   1. Locates makensis.exe (NSIS compiler) via PATH or registry
 *   2. Verifies the Neutralinojs build output exists
 *   3. Runs makensis to produce the final installer EXE
 *
 * Prerequisite: Run `npm run build` in desktop-app/ before this script.
 *
 * Usage (from project root):
 *   node build-installer.js
 *   npm run build:installer   (via package.json, which runs build first)
 */

"use strict";

const { spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const ROOT_DIR = path.resolve(__dirname);

/** Run a command and return its trimmed stdout. Throws on non-zero exit. */
function run(cmd, options = {}) {
  const result = spawnSync(cmd, {
    shell: true,
    encoding: "utf-8",
    stdio: "pipe",
    ...options,
  });
  if (result.status !== 0) {
    const err = (result.stderr || "").trim();
    throw new Error(`Command failed (exit ${result.status}): ${cmd}\n${err}`);
  }
  return (result.stdout || "").trim();
}

/** Log helpers */
const log = {
  step: (n, msg) => console.log(`\n[${n}] ${msg}`),
  ok: (msg) => console.log(`  ✓ ${msg}`),
  warn: (msg) => console.log(`  ⚠ ${msg}`),
  fatal: (msg) => {
    console.error(`\n  ✗ FATAL: ${msg}`);
    process.exit(1);
  },
};

// ---------------------------------------------------------------------------
// Step 1 — Locate makensis.exe
// ---------------------------------------------------------------------------

function findMakensis() {
  log.step(1, "Locating NSIS (makensis.exe)...");

  // Strategy A: check PATH
  try {
    const whereResult = run("where makensis", { stdio: "pipe" });
    if (whereResult) {
      const exe = whereResult.split(/\r?\n/)[0].trim();
      if (fs.existsSync(exe)) {
        log.ok(`Found via PATH: ${exe}`);
        return exe;
      }
    }
  } catch {
    // not in PATH — continue
  }

  // Strategy B: check common install locations
  const candidates = [
    "C:\\Program Files (x86)\\NSIS\\makensis.exe",
    "C:\\Program Files\\NSIS\\makensis.exe",
  ];
  for (const p of candidates) {
    if (fs.existsSync(p)) {
      log.ok(`Found at default location: ${p}`);
      return p;
    }
  }

  // Strategy C: query Windows registry for NSIS install location
  try {
    const regQuery =
      'reg query "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\NSIS" /v InstallLocation 2>nul || ' +
      'reg query "HKLM\\SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\NSIS" /v InstallLocation 2>nul';
    const regOutput = run(regQuery, { stdio: "pipe" });
    // Parse REG_SZ value (last token after "REG_SZ")
    const match = regOutput.match(/REG_SZ\s+(.+)/);
    if (match) {
      const installDir = match[1].trim();
      const exe = path.join(installDir, "makensis.exe");
      if (fs.existsSync(exe)) {
        log.ok(`Found via registry: ${exe}`);
        return exe;
      }
    }
  } catch {
    // registry entry not found — continue
  }

  log.fatal(
    "Could not find makensis.exe.\n" +
      "  • Make sure NSIS is installed: https://nsis.sourceforge.io/\n" +
      "  • Or add NSIS to your system PATH."
  );
}

// ---------------------------------------------------------------------------
// Step 2 — Verify build output
// ---------------------------------------------------------------------------

function verifyBuildOutput() {
  log.step(2, "Verifying build output...");

  const distDir = path.join(
    ROOT_DIR,
    "desktop-app",
    "dist",
    "markdown-viewer"
  );

  const required = [
    path.join(distDir, "markdown-viewer-win_x64.exe"),
  ];

  for (const f of required) {
    if (!fs.existsSync(f)) {
      log.fatal(
        `Build output missing: ${path.relative(ROOT_DIR, f)}\n` +
          "  Run 'npm run build' in desktop-app/ first."
      );
    }
    log.ok(`Found: ${path.relative(ROOT_DIR, f)}`);
  }
}

// ---------------------------------------------------------------------------
// Step 3 — Run makensis to produce the installer
// ---------------------------------------------------------------------------

function buildInstaller(makensisExe) {
  log.step(3, "Building NSIS installer...");

  const nsiScript = path.join(ROOT_DIR, "installer.nsi");

  if (!fs.existsSync(nsiScript)) {
    log.fatal(`Installer script not found: ${nsiScript}`);
  }

  const result = spawnSync(`"${makensisExe}"`, ["/INPUTCHARSET", "UTF8", `"${nsiScript}"`], {
    shell: true,
    cwd: ROOT_DIR,
    stdio: "inherit",
  });

  if (result.status !== 0) {
    log.fatal(`makensis exited with code ${result.status}`);
  }

  // Verify the output EXE was created
  const outputPath = path.join(
    ROOT_DIR,
    "desktop-app",
    "dist",
    "markdown-viewer",
    "Markdown-Viewer-Setup.exe"
  );

  if (fs.existsSync(outputPath)) {
    const stats = fs.statSync(outputPath);
    const sizeMB = (stats.size / 1024 / 1024).toFixed(2);
    log.ok(`Installer created: ${path.relative(ROOT_DIR, outputPath)} (${sizeMB} MB)`);
  } else {
    log.warn("makensis completed but output file was not found at the expected path.");
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function main() {
  console.log("============================================");
  console.log("  Markdown Viewer — Installer Builder");
  console.log("============================================");

  const makensis = findMakensis();
  verifyBuildOutput();
  buildInstaller(makensis);

  console.log("\n============================================");
  console.log("  Done! Installer built successfully.");
  console.log("============================================\n");
}

main();
