{ inputs, config, ... }:
let
  lc = config.flake.lib.livingCode;
  # Pi resolves color values through `vars`, so tokens name palette entries.
  piTheme = {
    "$schema" =
      "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
    name = lc.name;
    appearance = "dark";
    vars = lc.colors;
    colors = {
      accent = "teal";
      border = "surface2";
      borderAccent = "teal";
      borderMuted = "surface1";
      success = "moss";
      error = "flare";
      warning = "amber";
      muted = "subtext";
      dim = "comment";
      text = "text";
      thinkingText = "subtext";
      selectedBg = "surface1";
      scrollbarTrack = "surface0";
      scrollbarThumb = "overlay";
      searchMatchBg = "amber";
      searchMatchText = "base";
      userMessageBg = "surface0";
      userMessageText = "text";
      customMessageBg = "mantle";
      customMessageText = "text";
      customMessageLabel = "aqua";
      toolPendingBg = "surface0";
      toolSuccessBg = "mantle";
      toolErrorBg = "surface0";
      toolTitle = "steel";
      toolOutput = "text2";
      mdHeading = "teal";
      mdLink = "aqua";
      mdLinkUrl = "steel";
      mdCode = "amber";
      mdCodeBlock = "text";
      mdCodeBlockBorder = "surface2";
      mdQuote = "comment";
      mdQuoteBorder = "surface2";
      mdHr = "surface2";
      mdListBullet = "teal";
      toolDiffAdded = "moss";
      toolDiffRemoved = "flare";
      toolDiffContext = "subtext";
      syntaxComment = "comment";
      syntaxKeyword = "mint";
      syntaxFunction = "aqua";
      syntaxVariable = "text";
      syntaxString = "amber";
      syntaxNumber = "copper";
      syntaxType = "steel";
      syntaxOperator = "comment";
      syntaxPunctuation = "overlay";
      thinkingOff = "surface2";
      thinkingMinimal = "overlay";
      thinkingLow = "steel";
      thinkingMedium = "aqua";
      thinkingHigh = "mint";
      thinkingXhigh = "teal";
      thinkingMax = "orchid";
      bashMode = "copper";
    };
    export = {
      pageBg = "base";
      cardBg = "mantle";
      infoBg = "surface0";
    };
  };
in
{
  flake.modules.homeManager.pi =
    { pkgs, lib, ... }:
    {
      home.packages = [
        inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      # Pi discovers the package's pi.extensions manifest here. Keep the whole
      # source tree together so relative imports and package metadata resolve.
      home.file.".pi/agent/extensions/pi-anthropic-auth".source = inputs.pi-anthropic-auth;
      home.file.".pi/agent/themes/${lc.name}.json".text = builtins.toJSON piTheme;
      home.file.".pi/agent/extensions/terminal-statusline".source =
        "${inputs.pi-terminal-statusline}/extensions/statusline";

      # Keep settings writable so Pi can save preferences and package registrations.
      home.activation.piTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.python3}/bin/python3 - "$HOME/.pi/agent/settings.json" <<'PY'
        import json
        import pathlib
        import sys

        path = pathlib.Path(sys.argv[1])
        settings = json.loads(path.read_text()) if path.exists() else {}
        settings["theme"] = "${lc.name}"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(settings, indent=2) + "\n")
        PY
      '';
    };
}
