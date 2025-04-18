{ pkgs, anyrun, ... }:
{
  programs.anyrun = {
    enable = true;
    config = {
      x = {
        fraction = 0.5;
      };
      y = {
        fraction = 0.3;
      };
      width = {
        fraction = 0.3;
      };
      hideIcons = false;
      ignoreExclusiveZones = false;
      layer = "overlay";
      hidePluginInfo = true;
      closeOnClick = true;
      showResultsImmediately = false;
      maxEntries = null;

      plugins = [
        anyrun.packages.${pkgs.system}.applications
        anyrun.packages.${pkgs.system}.rink
        anyrun.packages.${pkgs.system}.translate
        anyrun.packages.${pkgs.system}.websearch
      ];
    };

    # Inline comments are supported for language injection into
    # multi-line strings with Treesitter! (Depends on your editor)

    extraCss = # css
      ''
                                window {
                        					background: transparent;
                        					border: none;
                                }
                                entry {
                        					border-color: #CBA6F7;
                                }
                                box {
        													border-radius: 12px;
                                }
      '';

    # extraConfigFiles."some-plugin.ron".text = ''
    #   Config(
    #     // for any other plugin
    #     // this file will be put in ~/.config/anyrun/some-plugin.ron
    #     // refer to docs of xdg.configFile for available options
    #   )
    # '';
  };
}
