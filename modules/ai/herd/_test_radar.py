"""Check the composed Home Manager config and Radar's immutable-config guard."""
import pathlib
import subprocess
import sys
import tomllib

radar = pathlib.Path(sys.argv[1])
with open(sys.argv[2], "rb") as file:
    config = tomllib.load(file)
with (radar / "herdr-plugin.toml").open("rb") as file:
    manifest = tomllib.load(file)

assert config["ui"]["sidebar"]["agents"]["rows"]
assert config["ui"]["sidebar"]["spaces"]["rows"]
assert "herdr-projects needs-you" in config["ui"]["tab_bar_right"][0]["command"]
keys = {entry["key"]: entry["command"] for entry in config["keys"]["command"]}
assert keys["prefix+a"] == "herdr-projects.open-popup"
assert keys["prefix+r"] == "hhdebb.herdr-radar.view-flip"
assert keys["prefix+comma"] == "hhdebb.herdr-radar.settings"
for section in ("actions", "panes", "startup", "events", "build"):
    for entry in manifest[section]:
        assert entry["command"][0] == str(radar / "bin/radar-node")
assert (radar / "share/fonts/truetype/HerdrAgentIconsMax-Regular.ttf").is_file()

subprocess.run(
    ["node", "-e", """
const assert = require('node:assert/strict');
const root = process.argv[1];
assert.deepEqual(require(root + '/lib/setup').ensure(), []);
assert.equal(require(root + '/lib/config').followAppearance, false);
assert.equal(require(root + '/lib/logos').resolveVariant(), 'font');
// The guard must return before attempting any filesystem access.
assert.match(require(root + '/lib/managed-config').checkedWrite(
  '/nonexistent/config.toml', 'changed', '/nonexistent/backup'
), /managed by Nix/);
""", str(radar)],
    check=True,
)
