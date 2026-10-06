// Exercise the functions shipped in the patched release, not a copy of them.
// The bundle is loaded in a VM so these checks need neither a display nor a
// running daemon. patchPhase fails if a future release changes the call sites.
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const vm = require("node:vm");

const source = fs.readFileSync(
  path.join(process.argv[2], "lib/terminal-browser/browser/dist/main.js"),
  "utf8",
);
const start = source.indexOf('var AUTO = "auto";');
const end = source.indexOf("// shared/src/config/search.ts", start);
assert.ok(start >= 0 && end > start, "render helpers are present in the bundle");
const context = vm.createContext({});
vm.runInContext(source.slice(start, end), context);
const { maxFps, renderEnv } = context;
const herdr = { HERDR_PANE_ID: "w1:p2" };
const automatic = { "render.presenter": "auto", "render.transport": "auto" };
const plain = (value) => JSON.parse(JSON.stringify(value));
const environment = (settings, env = {}) => ({
  ...env,
  ...plain(renderEnv((key) => settings[key], env)),
});

test("unknown display refresh rates do not accidentally uncap rendering", () => {
  for (const hz of [0, -1, NaN, Infinity]) {
    assert.equal(maxFps("display", hz), 60);
    assert.equal(maxFps("display", hz, herdr), 60);
  }
  assert.equal(maxFps("display", 144), 144);
  assert.equal(maxFps("display", 144, herdr), 60);
  assert.equal(maxFps("display", 60, herdr), 60);
  assert.equal(maxFps("display", 59.94, herdr), 59.94);
  assert.equal(maxFps("display", 24, herdr), 24);
});

test("explicit FPS settings still win, including uncapped", () => {
  for (const env of [{}, herdr]) {
    assert.equal(maxFps("uncapped", 144, env), 0);
    assert.equal(maxFps("60", 0, env), 60);
    assert.equal(maxFps("120", 0, env), 120);
    assert.equal(maxFps("12.5", 144, env), 12.5);
  }
});

test("Herdr automatic rendering uses a single whole-frame file", () => {
  assert.deepEqual(environment(automatic, herdr), {
    ...herdr,
    TERMINAL_BROWSER_PRESENT: "full",
    TERMINAL_BROWSER_FRAMES: "file",
  });
  assert.deepEqual(environment(automatic), {});
  assert.deepEqual(environment(automatic, { HERDR_ENV: "1" }), { HERDR_ENV: "1" });
});

test("explicit settings and environment transport/presenter overrides survive", () => {
  const env = {
    ...herdr,
    TERMINAL_BROWSER_PRESENT: "patched",
    TERMINAL_BROWSER_FRAMES: "inline",
  };
  assert.deepEqual(environment(automatic, env), env);
  const settings = { "render.presenter": "animation", "render.transport": "shared" };
  assert.deepEqual(environment(settings, env), {
    ...herdr,
    TERMINAL_BROWSER_PRESENT: "animation",
    TERMINAL_BROWSER_FRAMES: "shared",
  });
  assert.deepEqual(environment({ ...automatic, "render.transport": "inline" }, herdr), {
    ...herdr,
    TERMINAL_BROWSER_PRESENT: "full",
    TERMINAL_BROWSER_FRAMES: "inline",
  });
});

// Verify the actual Session call sites pass the per-session environment. The
// daemon can be started inside Herdr and later host a standalone session (or
// vice versa); its process.env is not a reliable rendering-profile selector.
const sessionEnvExpression = source.match(/sessionEnv: (\{ \.\.\.this\.ctx\.env, \.\.\.renderEnv[^\n]+\})/);
assert.ok(sessionEnvExpression, "Session supplies the native rendering environment");
vm.runInContext(
  `function nativeEnvironment() { return ${sessionEnvExpression[1]}; }`,
  context,
);
const applySettingsBody = source.match(/\n  applyRenderSettings\(\) \{([\s\S]*?)\n  \}/);
assert.ok(applySettingsBody, "Session applies render settings");
vm.runInContext(`function applySettings() {${applySettingsBody[1]}\n}`, context);
context.displayHz = () => 0;
context.ENGINE_LOG_FILE = "unused";

function session(env, settings = automatic) {
  let applied;
  return {
    ctx: { env },
    settings: { get: (key) => key === "render.fps" ? "display" : settings[key] },
    root: { setRender: (value) => { applied = plain(value); }, setLogFile: () => {} },
    native: function () { return plain(context.nativeEnvironment.call(this)); },
    apply: function () { context.applySettings.call(this); return applied; },
  };
}

test("mixed daemon sessions get independent profiles in both call sites", () => {
  const pane = session(herdr);
  const standalone = session({});
  for (const hz of [0, 144]) {
    context.displayHz = () => hz;
    assert.equal(pane.apply().maxFps, 60);
    assert.equal(pane.native().TERMINAL_BROWSER_PRESENT, "full");
    assert.equal(pane.native().TERMINAL_BROWSER_FRAMES, "file");
    assert.equal(standalone.apply().maxFps, hz || 60);
    assert.deepEqual(standalone.native(), {});
  }
});
