{ inputs, ... }:
{
  flake.modules.homeManager.pi =
    { pkgs, lib, ... }:
    {
      home.packages = [
        inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      home.file.".pi/agent/themes/catppuccin-mocha.json".source = ./catppuccin-mocha.json;

      # Keep settings writable so Pi can save preferences and package registrations.
      home.activation.piCatppuccin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.python3}/bin/python3 - "$HOME/.pi/agent/settings.json" <<'PY'
        import json
        import pathlib
        import sys

        path = pathlib.Path(sys.argv[1])
        settings = json.loads(path.read_text()) if path.exists() else {}
        settings["theme"] = "catppuccin-mocha"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(settings, indent=2) + "\n")
        PY
      '';
    };
}
