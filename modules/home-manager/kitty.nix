{ ... }:
{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };

    # Extra
    settings = {
      cursor_trail = "3";
      disable_ligatures = "always";
    }; 

    shellIntegration.enableFishIntegration = true;
  };
}
