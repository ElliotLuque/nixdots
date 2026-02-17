{ ... }:
{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font Propo";
      size = 14;
    };

    # Extra
    settings = {
      copy_on_select = "clipboard";
      cursor_trail = "1";
      disable_ligatures = "always";
    };

    shellIntegration.enableFishIntegration = true;
  };
}
