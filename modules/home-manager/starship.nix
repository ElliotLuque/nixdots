{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;

    settings = {
      character = {
        success_symbol = " [](bold blue)  [➜](bold green)";
        error_symbol = " [](bold blue)  [➜](bold red)";
      };
    };
  };
}
