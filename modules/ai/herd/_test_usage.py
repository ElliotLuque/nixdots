"""Check usage rows and the patched installer's declarative ownership seam."""
import json
import os
import pathlib
import subprocess
import sys
import tempfile
import tomllib

usage = pathlib.Path(sys.argv[1])
config_path = pathlib.Path(sys.argv[2])
with config_path.open("rb") as file:
    config = tomllib.load(file)
with (usage / "herdr-plugin.toml").open("rb") as file:
    manifest = tomllib.load(file)

assert manifest["id"] == "herdr-agent-quota"
assert manifest["version"] == "1.6.2"
assert manifest["build"][0]["command"][0].endswith("/bin/true")
assert (usage / "target/release/herdr-agent-quota").resolve().is_file()
keys = {entry["key"]: entry["command"] for entry in config["keys"]["command"]}
assert keys["prefix+shift+q"] == "herdr-agent-quota.open-settings"
assert keys["prefix+shift+r"] == "herdr-agent-quota.refresh"

agents = config["ui"]["sidebar"]["agents"]
for rows in [agents["rows"], *agents["rows_by_agent"].values()]:
    assert ["$quota_model"] in rows
    assert ["$quota_error"] in rows
    assert any("$quota_5h_normal" in row for row in rows)
    assert all(len(row) <= 16 for row in rows)

with tempfile.TemporaryDirectory() as directory:
    home = pathlib.Path(directory)
    herdr_config = home / ".config/herdr/config.toml"
    herdr_config.parent.mkdir(parents=True)
    herdr_config.symlink_to(config_path)
    claude_settings = home / ".claude/settings.json"
    claude_settings.parent.mkdir()
    original = {"statusLine": {"type": "command", "command": "echo original"}, "unrelated": True}
    claude_settings.write_text(json.dumps(original))
    state = home / "state"
    state.mkdir()
    env = {key: value for key, value in os.environ.items() if not key.startswith("HERDR_")}
    env.update(
        HOME=str(home),
        XDG_CONFIG_HOME=str(home / ".config"),
        XDG_DATA_HOME=str(home / ".local/share"),
        CLAUDE_SETTINGS_FILE=str(claude_settings),
        HERDR_PLUGIN_STATE_DIR=str(state),
        # Never contact a live Herdr server in a build check.
        HERDR_BIN_PATH=str(home / "no-herdr"),
    )
    command = [str(usage / "bin/herdr-agent-usage"), "configure", "--agent", "claude"]
    before = herdr_config.read_bytes()
    subprocess.run(command + ["--apply", "--sidebar-layout", "stacked"], env=env, check=True)
    installed = json.loads(claude_settings.read_text())
    assert installed["unrelated"] is True
    assert "claude-statusline" in installed["statusLine"]["command"]
    assert herdr_config.is_symlink() and herdr_config.read_bytes() == before
    assert not (home / ".local/share/fonts").exists()
    subprocess.run(command + ["--uninstall"], env=env, check=True)
    assert json.loads(claude_settings.read_text()) == original
    assert herdr_config.read_bytes() == before
