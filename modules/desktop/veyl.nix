{ inputs, config, ... }:
let
  livingCode = config.flake.lib.livingCode;
in
{
  flake.modules.homeManager.veyl = {
    imports = [ inputs.veyl.homeManagerModules.veyl ];

    programs.veyl = {
      enable = true;
      systemd.enable = true;
      settings = {
        scheme = livingCode.name;
        wallpaper = ../../wallpaper/living-code/${livingCode.flavor}/painting-livingcode.png;
        webSearch = "https://google.com/search?q=%s";
        brain.provider = "claude-code";
        lockAfter = 15;
      };
    };
  };
}
