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

assert config["theme"]["name"] == "catppuccin"
colors = config["theme"]["custom"]
assert colors["sidebar_bg"] == "#181825"
assert colors["active_row_bg"] == "#313244"
assert colors["selection_bg"] == "#45475a"
assert colors["surface_dim"] == "#6c7086"
assert colors["overlay0"] == "#a6adc8"
assert colors["overlay1"] == "#bac2de"


def luminance(hex_color):
    rgb = [int(hex_color[i : i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in rgb]
    return sum(v * w for v, w in zip(linear, (0.2126, 0.7152, 0.0722)))


def contrast(foreground, background):
    light, dark = sorted((luminance(foreground), luminance(background)), reverse=True)
    return (light + 0.05) / (dark + 0.05)


assert contrast(colors["surface_dim"], colors["sidebar_bg"]) >= 3
# Text colours inherited from the built-in Mocha theme, plus our muted text.
for foreground, background in (
    ("#a6adc8", colors["sidebar_bg"]),  # Unfocused workspace name.
    ("#cdd6f4", colors["active_row_bg"]),
    ("#cdd6f4", colors["selection_bg"]),
    (colors["overlay0"], colors["sidebar_bg"]),
    (colors["overlay0"], "#313244"),  # Inactive tab surface.
    (colors["overlay1"], colors["selection_bg"]),
):
    assert contrast(foreground, background) >= 4.5, (foreground, background)

assert config["ui"]["pane_borders"] == "always"
assert config["ui"]["pane_outer_borders"] is True
assert config["ui"]["sidebar"]["agents"]["rows"]
spaces = config["ui"]["sidebar"]["spaces"]
assert spaces["row_gap"] == 0
# An unstyled built-in token preserves Herdr's focused foreground and weight,
# and keeps names visible even when Radar has not published metadata yet.
assert spaces["rows"][0][-1] == "workspace"
assert all(
    cell != "$space_label"
    and (not isinstance(cell, dict) or cell["token"] != "$space_label")
    for row in spaces["rows"]
    for cell in row
)
keys = {entry["key"]: entry["command"] for entry in config["keys"]["command"]}
assert keys["prefix+r"] == "hhdebb.herdr-radar.view-flip"
assert keys["prefix+comma"] == "hhdebb.herdr-radar.settings"
for section in ("actions", "panes", "startup", "events", "build"):
    for entry in manifest[section]:
        assert entry["command"][0] == str(radar / "bin/radar-node")
assert (radar / "share/fonts/truetype/HerdrAgentIconsMax-Regular.ttf").is_file()

subprocess.run(
    [
        "node",
        "-e",
        """
const assert = require('node:assert/strict');
const root = process.argv[1];
assert.deepEqual(require(root + '/lib/setup').ensure(), []);
assert.equal(require(root + '/lib/config').followAppearance, false);
assert.equal(require(root + '/lib/logos').resolveVariant(), 'font');
// The guard must return before attempting any filesystem access.
assert.match(require(root + '/lib/managed-config').checkedWrite(
  '/nonexistent/config.toml', 'changed', '/nonexistent/backup'
), /managed by Nix/);
""",
        str(radar),
    ],
    check=True,
)
