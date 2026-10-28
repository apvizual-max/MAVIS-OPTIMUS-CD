// ask-jules-notebook.mjs - interoghez "Jules Notebook" (Google Notebooks / NotebookLM)
// prin layer-ul MCP local, prin protocolul stdio.
//
// DE CE EXISTA ASTA:
//   "Jules Notebook" nu e un fisier local - e un notebook cloud. Fara un
//   client, proiectul nu poate consulta baza de cunostinte pe care Popy o
//   cere ca instrument de indrumare si de verificare finala.
//
// MEASURED 2026-10-28: serverul minimax-notebooklm raspunde, autentificat,
//   cu 4 unelte: nblm_health, nblm_list_notebooks, nblm_get_sources, nblm_ask.
//   nblm_ask are schema {notebook, question}.
//
// LOGICA:
//   1. porneste serverul MCP ca proces copil (stdio)
//   2. handshake: initialize -> notifications/initialized -> tools/list
//   3. apeleaza unealta si afiseaza raspunsul RAW (fara interpretare)
//   4. exit 0 = reusit, 1 = unelta a esuat, 2 = serverul nu a fost gasit
//
// REGULA: nu se inventa nimic. Daca stramosul nu exista sau raspunsul e gol,
//   se raporteaza exact asa - nu se completeaza cu memorie.
//
// Usage:
//   node ask-jules-notebook.mjs --list
//   node ask-jules-notebook.mjs --ask "Ce reguli are fluxul Jules pe push?" --notebook JULES
//   node ask-jules-notebook.mjs --ask "..." --notebook JULES --layer <path-to-minimax-notebooklm.js>

import { spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

const LAYER_CANDIDATES = [
  path.join(
    os.homedir(),
    ".minimax-agent",
    "projects",
    "Mavis-Optimus-Dashboard",
    "Mavis-Google_Access",
    "google-layer",
    "minimax-notebooklm.js"
  ),
  path.join(
    os.homedir(),
    ".minimax-agent",
    "projects",
    "Mavis-Google_Access",
    "google-layer",
    "minimax-notebooklm.js"
  ),
];

function argOf(flag, dflt) {
  const i = process.argv.indexOf(flag);
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : dflt;
}
const has = (flag) => process.argv.includes(flag);

const QUESTION = argOf("--ask", "");
const NOTEBOOK = argOf("--notebook", "JULES");
const TIMEOUT_MS = parseInt(argOf("--timeout", "180000"), 10);

let FILE = argOf("--layer", "");
if (!FILE) {
  FILE = LAYER_CANDIDATES.find((p) => fs.existsSync(p)) || "";
}
if (!FILE || !fs.existsSync(FILE)) {
  console.log("VERDICT=LAYER_MISSING");
  console.log("Cautat in:");
  for (const c of LAYER_CANDIDATES) console.log("  " + c);
  console.log("Poti preciza: --layer <cale>");
  process.exit(2);
}
console.log("LAYER=" + FILE);

const NODE = process.execPath;
const child = spawn(NODE, [FILE], { windowsHide: true });
const pending = new Map();
let buffer = "";
let stderr = "";

child.stdout.on("data", (chunk) => {
  buffer += chunk.toString();
  let i;
  while ((i = buffer.indexOf("\n")) >= 0) {
    const line = buffer.slice(0, i).trim();
    buffer = buffer.slice(i + 1);
    if (!line) continue;
    let msg;
    try {
      msg = JSON.parse(line);
    } catch {
      continue;
    }
    if (msg.id !== undefined && pending.has(msg.id)) {
      const res = pending.get(msg.id);
      pending.delete(msg.id);
      res(msg);
    }
  }
});
child.stderr.on("data", (c) => {
  stderr += c.toString();
});

let nextId = 1;
function call(method, params) {
  const id = nextId++;
  const p = new Promise((res) => pending.set(id, res));
  child.stdin.write(JSON.stringify({ jsonrpc: "2.0", id, method, params }) + "\n");
  return p;
}
function notify(method, params) {
  child.stdin.write(JSON.stringify({ jsonrpc: "2.0", method, params }) + "\n");
}
const timeout = (ms) => new Promise((r) => setTimeout(() => r(null), ms));

function textOf(res) {
  const t =
    res && res.result && res.result.content && res.result.content[0] && res.result.content[0].text
      ? res.result.content[0].text
      : null;
  return t !== null ? t : JSON.stringify(res);
}

(async () => {
  const init = await call("initialize", {
    protocolVersion: "2024-11-05",
    capabilities: {},
    clientInfo: { name: "ask-jules-notebook", version: "1.0.0" },
  });
  const info = init && init.result && init.result.serverInfo;
  console.log(
    "SERVER=" +
      (info ? info.name : "?") +
      " VERSION=" +
      (info ? info.version : "?") +
      " INITIALIZE_OK=" +
      (init && init.result ? 1 : 0)
  );
  notify("notifications/initialized", {});

  const list = await call("tools/list", {});
  const tools = list && list.result && Array.isArray(list.result.tools) ? list.result.tools : [];
  console.log("TOOLS=" + tools.map((t) => t.name).join("|"));

  if (has("--list")) {
    const res = await call("tools/call", { name: "nblm_list_notebooks", arguments: {} });
    console.log("--- LIST ---");
    console.log(textOf(res));
    child.kill();
    process.exit(0);
  }

  if (!QUESTION) {
    console.log("VERDICT=NO_QUESTION");
    console.log("Folosi --ask \"intrebarea\" sau --list");
    child.kill();
    process.exit(2);
  }

  const res = await timeout(TIMEOUT_MS) ||
    (await call("tools/call", { name: "nblm_ask", arguments: { notebook: NOTEBOOK, question: QUESTION } }));
  if (!res) {
    console.log("VERDICT=TIMEOUT");
    child.kill();
    process.exit(1);
  }
  const isError = res && res.result && res.result.isError ? "1" : "0";
  console.log("IS_ERROR=" + isError);
  console.log("--- ANSWER ---");
  console.log(textOf(res));
  if (stderr.trim()) {
    console.log("--- STDERR ---");
    console.log(stderr.trim());
  }
  child.kill();
  process.exit(isError === "1" ? 1 : 0);
})();
