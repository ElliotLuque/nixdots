"""Reconcile the pinned theme without replacing Paseo's mutable configuration."""

import json
import os
from pathlib import Path
import shutil
import sys
import tempfile

config_path = Path(sys.argv[1])
plugin_path = sys.argv[2]
config = json.loads(config_path.read_text()) if config_path.exists() else {}
plugins = config.setdefault("plugins", {})

# Enabling the global switch must not enable unrelated, previously dormant code.
if not config.get("pluginsEnabled", False):
    for plugin_id, plugin in plugins.items():
        if plugin_id != "catppuccin-theme" and plugin.get("enabled", True):
            plugin["enabled"] = False

plugins["catppuccin-theme"] = {
    "source": "directory",
    "path": plugin_path,
    "enabled": True,
}
config["pluginsEnabled"] = True
contents = json.dumps(config, indent=2) + "\n"
if config_path.exists() and json.loads(config_path.read_text()) == config:
    sys.exit(0)

config_path.parent.mkdir(parents=True, exist_ok=True)
if config_path.exists():
    backup = config_path.with_name("config.json.before-nix-catppuccin")
    if not backup.exists():
        shutil.copy2(config_path, backup)
        backup.chmod(0o600)

fd, temporary = tempfile.mkstemp(prefix=".config-", dir=config_path.parent)
try:
    with os.fdopen(fd, "w") as output:
        output.write(contents)
    os.replace(temporary, config_path)
finally:
    if os.path.exists(temporary):
        os.unlink(temporary)
print("Catppuccin registered. Restart the Paseo daemon to load the pinned theme.")
