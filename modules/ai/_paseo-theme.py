"""Reconcile the pinned theme plugin without replacing Paseo's mutable configuration."""

import json
import os
from pathlib import Path
import shutil
import sys
import tempfile

config_path = Path(sys.argv[1])
plugin_id = sys.argv[2]
plugin_path = sys.argv[3]
# Theme plugins this configuration previously managed.
RETIRED = {"catppuccin-theme"}

config = json.loads(config_path.read_text()) if config_path.exists() else {}
original = json.loads(json.dumps(config))
plugins = config.setdefault("plugins", {})

# Enabling the global switch must not enable unrelated, previously dormant code.
if not config.get("pluginsEnabled", False):
    for other_id, plugin in plugins.items():
        if other_id != plugin_id and plugin.get("enabled", True):
            plugin["enabled"] = False

for retired_id in RETIRED - {plugin_id}:
    plugins.pop(retired_id, None)

plugins[plugin_id] = {
    "source": "directory",
    "path": plugin_path,
    "enabled": True,
}
config["pluginsEnabled"] = True
if config == original:
    sys.exit(0)

config_path.parent.mkdir(parents=True, exist_ok=True)
if config_path.exists():
    backup = config_path.with_name("config.json.before-nix-theme")
    if not backup.exists():
        shutil.copy2(config_path, backup)
        backup.chmod(0o600)

fd, temporary = tempfile.mkstemp(prefix=".config-", dir=config_path.parent)
try:
    with os.fdopen(fd, "w") as output:
        output.write(json.dumps(config, indent=2) + "\n")
    os.replace(temporary, config_path)
finally:
    if os.path.exists(temporary):
        os.unlink(temporary)
print(f"{plugin_id} registered. Restart the Paseo daemon, then pick the theme in Settings -> Appearance.")
