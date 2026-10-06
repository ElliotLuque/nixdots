"""Append usage-only rows without replacing Radar's identity/state rows."""
import pathlib
import sys
import tomlkit

path = pathlib.Path(sys.argv[1])
document = tomlkit.parse(path.read_text())
agents = document["ui"]["sidebar"]["agents"]


def severity_row(base, variants, shared=False):
    tokens = [f"${base}_{variant}" for variant in variants]
    if shared:
        tokens += [f"$quota_share_{base.removeprefix('quota_')}_{variant}" for variant in variants]
    return tokens


usage_rows = [
    ["$quota_model"],
    ["$quota_context"] + severity_row("quota_context", ["normal", "warning", "danger"]),
    severity_row("quota_5h", ["normal", "warning", "danger", "unknown"], shared=True),
    severity_row("quota_week", ["normal", "warning", "danger", "unknown"], shared=True),
    severity_row("quota_week_inline", ["normal", "warning", "danger", "unknown"], shared=True),
    severity_row("quota_month", ["normal", "warning", "danger", "unknown"], shared=True),
    ["$quota_error"],
]
for rows in [agents["rows"], *agents.get("rows_by_agent", {}).values()]:
    for row in usage_rows:
        rows.append(row)
path.write_text(tomlkit.dumps(document))
