{ ... }:
{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 14;
    };

    # Extra
    settings = {
      cursor_trail = "1";
      disable_ligatures = "always";
    };

    shellIntegration.enableFishIntegration = true;
  };
}
