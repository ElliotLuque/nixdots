{ inputs, config, ... }:
{
  flake.modules.homeManager.herdr =
    { pkgs, lib, ... }:
    {
      imports = with config.flake.modules.homeManager; [
        hunk-review
        herdr-worktrunk
        herdr-projects
      ];

      home.packages = [ inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default ];

      # Keep root settings before the integrations' TOML tables/keybindings.
      xdg.configFile."herdr/config.toml".text = lib.mkBefore ''
        onboarding = false

        [theme]
        name = "catppuccin"

        [ui]
        status_indicators = "symbols"

        [ui.toast]
        delivery = "system"
      '';
    };
}
